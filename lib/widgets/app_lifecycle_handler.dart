import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/app_lock_service.dart';
import '../services/firestore_service.dart';
import '../screens/app_lock_verify_screen.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  final GlobalKey<NavigatorState> navigatorKey;

  const AppLifecycleHandler({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState
    extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  final FirestoreService firestoreService =
      FirestoreService();

  final AuthService authService =
      AuthService();

  final AppLockService appLockService =
      AppLockService();

  bool _appReady = false;

  bool _shouldLockOnResume = false;

  bool _isLockScreenOpen = false;

  Timer? _lockCheckTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _setOnline();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _appReady = true;
    });
  }

  // =========================================================
  // ONLINE
  // =========================================================

  Future<void> _setOnline() async {
    try {
      final userId =
          await authService.getUserId();

      await firestoreService.setUserOnline(userId);
    } catch (e) {
      debugPrint(
        "ONLINE ERROR: $e",
      );
    }
  }

  // =========================================================
  // OFFLINE
  // =========================================================

  Future<void> _setOffline() async {
    try {
      final userId =
          await authService.getUserId();

      await firestoreService.setUserOffline(userId);
    } catch (e) {
      debugPrint(
        "OFFLINE ERROR: $e",
      );
    }
  }

  // =========================================================
  // CHECK APP LOCK
  // =========================================================

  Future<void> _checkAndShowAppLock() async {
    if (!_appReady) {
      return;
    }

    if (!_shouldLockOnResume) {
      return;
    }

    if (_isLockScreenOpen) {
      return;
    }

    final enabled =
        await appLockService.isAppLockEnabled();

    if (!mounted) return;

    if (!enabled) {
      _shouldLockOnResume = false;
      return;
    }

    final navigator =
        widget.navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    _isLockScreenOpen = true;

    try {
      // Give Flutter time to finish the previous
      // lifecycle/navigation transition.
      await Future.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted) return;

      final currentNavigator =
          widget.navigatorKey.currentState;

      if (currentNavigator == null) {
        _isLockScreenOpen = false;
        return;
      }

      await currentNavigator.push(
        MaterialPageRoute(
          builder: (_) =>
              const AppLockVerifyScreen(),
        ),
      );
    } finally {
      _isLockScreenOpen = false;
      _shouldLockOnResume = false;
    }
  }

  // =========================================================
  // LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    debugPrint(
      "Lifecycle : $state",
    );

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();

        // IMPORTANT:
        // Do not immediately open App Lock.
        // Wait until Flutter finishes restoring
        // the application navigation stack.
        _lockCheckTimer?.cancel();

        _lockCheckTimer = Timer(
          const Duration(milliseconds: 350),
          () {
            if (!mounted) return;

            _checkAndShowAppLock();
          },
        );

        break;

      case AppLifecycleState.inactive:
        _setOffline();

        if (_appReady) {
          _shouldLockOnResume = true;
        }

        break;

      case AppLifecycleState.paused:
        _setOffline();

        if (_appReady) {
          _shouldLockOnResume = true;
        }

        break;

      case AppLifecycleState.hidden:
        _setOffline();

        if (_appReady) {
          _shouldLockOnResume = true;
        }

        break;

      case AppLifecycleState.detached:
        _setOffline();

        break;
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _lockCheckTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    _setOffline();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}