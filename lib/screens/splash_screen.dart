import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final bool isLoggedIn =
        await authService.isLoggedIn();

    final bool hasProfile =
        await authService.hasUserProfile();

if (!mounted) return;

Widget nextScreen;

if (!isLoggedIn) {
  nextScreen = const WelcomeScreen();
} else if (!hasProfile) {
  nextScreen = const ProfileSetupScreen();
} else {
  nextScreen = HomeScreen();
}

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => nextScreen,
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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