import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'app_lock_verify_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService authService = AuthService();

  final AppLockService appLockService =
      AppLockService();

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  Future<void> checkLogin() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final bool isLoggedIn =
        await authService.isLoggedIn();

    final bool hasProfile =
        await authService.hasUserProfile();

    if (!mounted) return;

    // =========================================================
    // NOT LOGGED IN
    // =========================================================

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const WelcomeScreen(),
        ),
      );

      return;
    }

    // =========================================================
    // PROFILE NOT COMPLETED
    // =========================================================

    if (!hasProfile) {
      final String phoneNumber =
          await authService.getPhoneNumber();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            phoneNumber: phoneNumber,
          ),
        ),
      );

      return;
    }

    // =========================================================
    // LOGGED IN + PROFILE COMPLETED
    // =========================================================

    final bool appLockEnabled =
        await appLockService.isAppLockEnabled();

    if (!mounted) return;

    // =========================================================
    // APP LOCK ENABLED
    // =========================================================

    if (appLockEnabled) {
      final result =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AppLockVerifyScreen(),
        ),
      );

      if (!mounted) return;

      // Correct PIN se AppLockVerifyScreen pop hua.
      // Ab directly HomeScreen par jayenge.
      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(),
          ),
        );
      }

      return;
    }

    // =========================================================
    // APP LOCK DISABLED
    // =========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'NChat',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}