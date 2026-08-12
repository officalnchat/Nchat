import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/app_colors.dart';

class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() =>
      _AppLockSetupScreenState();
}

class _AppLockSetupScreenState
    extends State<AppLockSetupScreen> {
  final TextEditingController pinController =
      TextEditingController();

  final TextEditingController confirmPinController =
      TextEditingController();

  final TextEditingController answer1Controller =
      TextEditingController();

  final TextEditingController answer2Controller =
      TextEditingController();

  final AppLockService appLockService =
      AppLockService();

  bool isSaving = false;

  String selectedQuestion1 =
      "What is your childhood nickname?";

  String selectedQuestion2 =
      "What is your favorite place?";

  final List<String> securityQuestions = [
    "What is your childhood nickname?",
    "What is your favorite place?",
    "What was the name of your first school?",
    "What is your favorite food?",
    "What is your favorite movie?",
    "What is your best friend's nickname?",
  ];

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    answer1Controller.dispose();
    answer2Controller.dispose();
    super.dispose();
  }

  // =========================================================
  // SET PIN
  // =========================================================

  Future<void> _setPin() async {
    final pin = pinController.text.trim();
    final confirmPin =
        confirmPinController.text.trim();

    final answer1 =
        answer1Controller.text.trim();

    final answer2 =
        answer2Controller.text.trim();

    // -------------------------
    // PIN VALIDATION
    // -------------------------

    if (pin.length != 4) {
      _showMessage(
        "PIN must be exactly 4 digits",
      );
      return;
    }

    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      _showMessage(
        "PIN can contain numbers only",
      );
      return;
    }

    if (confirmPin != pin) {
      _showMessage(
        "PINs do not match",
      );
      return;
    }

    // -------------------------
    // SECURITY ANSWERS
    // -------------------------

    if (answer1.isEmpty) {
      _showMessage(
        "Please enter answer for Security Question 1",
      );
      return;
    }

    if (answer2.isEmpty) {
      _showMessage(
        "Please enter answer for Security Question 2",
      );
      return;
    }

    // -------------------------
    // SAME QUESTION CHECK
    // -------------------------

    if (selectedQuestion1 == selectedQuestion2) {
      _showMessage(
        "Please select two different security questions",
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // -------------------------
      // SAVE PIN
      // -------------------------

      await appLockService.enableAppLock(pin);

      // -------------------------
      // SAVE SECURITY QUESTIONS
      // -------------------------

      await appLockService.saveSecurityQuestions(
        question1: selectedQuestion1,
        answer1: answer1,
        question2: selectedQuestion2,
        answer2: answer2,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "App Lock enabled successfully",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Failed to save App Lock",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
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
  // SECURITY QUESTION DROPDOWN
  // =========================================================

  Widget _questionDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: "Security Question",
        border: OutlineInputBorder(),
      ),
      items: securityQuestions
          .map(
            (question) => DropdownMenuItem<String>(
              value: question,
              child: Text(
                question,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isSaving ? null : onChanged,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "App Lock",
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
              const SizedBox(height: 25),

              // =================================================
              // LOCK ICON
              // =================================================

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
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
                "Set App Lock PIN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create a 4-digit PIN and security questions to protect your NChat app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // PIN
              // =================================================

              TextField(
                controller: pinController,
                keyboardType:
                    TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "Enter PIN",
                  hintText: "4-digit PIN",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // CONFIRM PIN
              // =================================================

              TextField(
                controller: confirmPinController,
                keyboardType:
                    TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "Confirm PIN",
                  hintText: "Enter PIN again",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // SECURITY QUESTION 1
              // =================================================

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Security Question 1",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _questionDropdown(
                value: selectedQuestion1,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedQuestion1 = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: answer1Controller,
                textInputAction:
                    TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Answer",
                  hintText:
                      "Enter your answer",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // SECURITY QUESTION 2
              // =================================================

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Security Question 2",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _questionDropdown(
                value: selectedQuestion2,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedQuestion2 = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: answer2Controller,
                textInputAction:
                    TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Answer",
                  hintText:
                      "Enter your answer",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // INFO
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Remember your security answers. They will be used if you forget your App Lock PIN.",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // SET PIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : _setPin,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Set PIN",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}