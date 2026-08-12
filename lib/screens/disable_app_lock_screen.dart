import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/app_colors.dart';

class AppLockDisableScreen extends StatefulWidget {
  const AppLockDisableScreen({super.key});

  @override
  State<AppLockDisableScreen> createState() =>
      _AppLockDisableScreenState();
}

class _AppLockDisableScreenState
    extends State<AppLockDisableScreen> {
  final TextEditingController pinController =
      TextEditingController();

  final AppLockService appLockService =
      AppLockService();

  bool isChecking = false;
  bool isLockedOut = false;
  Duration remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  // =========================================================
  // CHECK LOCKOUT
  // =========================================================

  Future<void> _checkLockout() async {
    final locked = await appLockService.isLockedOut();

    if (!mounted) return;

    if (locked) {
      final duration =
          await appLockService.getRemainingLockTime();

      if (!mounted) return;

      setState(() {
        isLockedOut = true;
        remainingTime = duration;
      });

      _startTimer();
    }
  }

  // =========================================================
  // TIMER
  // =========================================================

  void _startTimer() {
    Future.delayed(
      const Duration(seconds: 1),
      () async {
        if (!mounted) return;

        final duration =
            await appLockService.getRemainingLockTime();

        if (!mounted) return;

        if (duration <= Duration.zero) {
          setState(() {
            isLockedOut = false;
            remainingTime = Duration.zero;
          });

          return;
        }

        setState(() {
          remainingTime = duration;
        });

        _startTimer();
      },
    );
  }

  // =========================================================
  // VERIFY PIN
  // =========================================================

  Future<void> _disableAppLock() async {
    if (isChecking || isLockedOut) {
      return;
    }

    final pin = pinController.text.trim();

    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      _showMessage("Enter your 4-digit PIN");
      return;
    }

    setState(() {
      isChecking = true;
    });

    try {
      final isCorrect =
          await appLockService.verifyPin(pin);

      if (!mounted) return;

      if (isCorrect) {
        await appLockService.disableAppLock();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "App Lock disabled successfully",
            ),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      // Wrong PIN
      final lockDuration =
          await appLockService.recordFailedAttempt();

      if (!mounted) return;

      pinController.clear();

      if (lockDuration > Duration.zero) {
        setState(() {
          isLockedOut = true;
          remainingTime = lockDuration;
        });

        _startTimer();

        _showMessage(
          "Too many wrong attempts. Try again later.",
        );
      } else {
        final attempts =
            await appLockService.getFailedAttempts();

        if (!mounted) return;

        final remainingAttempts =
            4 - attempts;

        _showMessage(
          remainingAttempts > 0
              ? "Wrong PIN. $remainingAttempts attempt(s) remaining."
              : "Wrong PIN.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final seconds =
        remainingTime.inSeconds;

    final minutes =
        seconds ~/ 60;

    final remainingSeconds =
        seconds % 60;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Disable App Lock",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 35),

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Disable App Lock",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter your current PIN to disable App Lock.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              if (isLockedOut) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(12),
                    color: Colors.red.withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.red,
                        size: 35,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Temporarily locked",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        minutes > 0
                            ? "Try again in ${minutes}m ${remainingSeconds}s"
                            : "Try again in ${remainingSeconds}s",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                TextField(
                  controller: pinController,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration:
                      const InputDecoration(
                    labelText: "Current PIN",
                    hintText: "Enter 4-digit PIN",
                    border:
                        OutlineInputBorder(),
                    counterText: "",
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        isChecking
                            ? null
                            : _disableAppLock,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: isChecking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Disable App Lock",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}