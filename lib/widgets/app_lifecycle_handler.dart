import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    super.key,
    required this.child,
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

  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _setOnline();
  }

  Future<void> _setOnline() async {
    final userId = await authService.getUserId();

    debugPrint("🟢 ONLINE USER : $userId");

    await firestoreService.setUserOnline(userId);

    debugPrint("🟢 ONLINE UPDATED");
  }

  Future<void> _setOffline() async {
    final userId = await authService.getUserId();

    debugPrint("🔴 OFFLINE USER : $userId");

    await firestoreService.setUserOffline(userId);

    debugPrint("🔴 OFFLINE UPDATED");
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    debugPrint("Lifecycle : $state");

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();
        break;

      case AppLifecycleState.inactive:
        _setOffline();
        break;

      case AppLifecycleState.paused:
        _setOffline();
        break;

      case AppLifecycleState.hidden:
        _setOffline();
        break;

      case AppLifecycleState.detached:
        _setOffline();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _setOffline();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}