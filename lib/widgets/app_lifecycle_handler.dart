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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _setOnline();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      _appReady = true;
    });
  }

  // =========================================================
  // ONLINE
  // =========================================================

  Future<void> _setOnline() async {
    final userId =
        await authService.getUserId();

    debugPrint(
      "🟢 ONLINE USER : $userId",
    );

    await firestoreService
        .setUserOnline(userId);

    debugPrint(
      "🟢 ONLINE UPDATED",
    );
  }

  // =========================================================
  // OFFLINE
  // =========================================================

  Future<void> _setOffline() async {
    final userId =
        await authService.getUserId();

    debugPrint(
      "🔴 OFFLINE USER : $userId",
    );

    await firestoreService
        .setUserOffline(userId);

    debugPrint(
      "🔴 OFFLINE UPDATED",
    );
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
        await appLockService
            .isAppLockEnabled();

    if (!enabled) {
      _shouldLockOnResume = false;
      return;
    }

    if (!mounted) return;

    final navigator =
        widget.navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    _isLockScreenOpen = true;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            const AppLockVerifyScreen(),
      ),
    );

    _isLockScreenOpen = false;

    _shouldLockOnResume = false;
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

        _checkAndShowAppLock();

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
    WidgetsBinding.instance
        .removeObserver(this);

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