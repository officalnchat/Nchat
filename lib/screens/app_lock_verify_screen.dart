import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/app_colors.dart';

class AppLockVerifyScreen extends StatefulWidget {
  const AppLockVerifyScreen({
    super.key,
  });

  @override
  State<AppLockVerifyScreen> createState() =>
      _AppLockVerifyScreenState();
}

class _AppLockVerifyScreenState
    extends State<AppLockVerifyScreen> {
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
    final locked =
        await appLockService.isLockedOut();

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

  Future<void> _verifyPin() async {
    if (isChecking || isLockedOut) {
      return;
    }

    final pin =
        pinController.text.trim();

    if (!RegExp(r'^[0-9]{4}$')
        .hasMatch(pin)) {
      _showMessage(
        "Enter your 4-digit PIN",
      );

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
        // Correct PIN
        await appLockService.resetFailedAttempts();

        if (!mounted) return;

        Navigator.of(context).pop(true);

        return;
      }

      // =====================================================
      // WRONG PIN
      // =====================================================

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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
              AppColors.primary,
          elevation: 0,
          title: const Text(
            "NChat",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // =================================================
                // LOCK ICON
                // =================================================

                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    color: AppColors.primary
                        .withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 52,
                    color:
                        AppColors.primary,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "NChat is Locked",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Enter your App Lock PIN to continue.",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                // =================================================
                // LOCKOUT
                // =================================================

                if (isLockedOut) ...[
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      color: Colors.red
                          .withValues(
                        alpha: 0.08,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.red,
                          size: 38,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          "Temporarily locked",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          minutes > 0
                              ? "Try again in ${minutes}m ${remainingSeconds}s"
                              : "Try again in ${remainingSeconds}s",
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // =================================================
                  // PIN
                  // =================================================

                  TextField(
                    controller:
                        pinController,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    autofocus: true,
                    textAlign:
                        TextAlign.center,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "App Lock PIN",
                      hintText:
                          "Enter 4-digit PIN",
                      border:
                          OutlineInputBorder(),
                      counterText: "",
                    ),
                    onSubmitted: (_) {
                      _verifyPin();
                    },
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // =================================================
                  // UNLOCK BUTTON
                  // =================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          isChecking
                              ? null
                              : _verifyPin,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors
                                .primary,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          isChecking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Unlock NChat",
                                  style:
                                      TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}