import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/app_colors.dart';

class ChangeAppLockPinScreen extends StatefulWidget {
  const ChangeAppLockPinScreen({super.key});

  @override
  State<ChangeAppLockPinScreen> createState() =>
      _ChangeAppLockPinScreenState();
}

class _ChangeAppLockPinScreenState
    extends State<ChangeAppLockPinScreen> {
  final TextEditingController currentPinController =
      TextEditingController();

  final TextEditingController newPinController =
      TextEditingController();

  final TextEditingController confirmPinController =
      TextEditingController();

  final AppLockService appLockService =
      AppLockService();

  bool isSaving = false;

  @override
  void dispose() {
    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  // =========================================================
  // CHANGE PIN
  // =========================================================

  Future<void> _changePin() async {
    final currentPin =
        currentPinController.text.trim();

    final newPin =
        newPinController.text.trim();

    final confirmPin =
        confirmPinController.text.trim();

    if (!RegExp(r'^[0-9]{4}$').hasMatch(currentPin)) {
      _showMessage("Enter your current 4-digit PIN");
      return;
    }

    if (!RegExp(r'^[0-9]{4}$').hasMatch(newPin)) {
      _showMessage("New PIN must be exactly 4 digits");
      return;
    }

    if (newPin == currentPin) {
      _showMessage(
        "New PIN must be different from current PIN",
      );
      return;
    }

    if (newPin != confirmPin) {
      _showMessage("New PINs do not match");
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Verify current PIN first
      final isCurrentPinCorrect =
          await appLockService.verifyPin(currentPin);

      if (!mounted) return;

      if (!isCurrentPinCorrect) {
        _showMessage("Current PIN is incorrect");
        currentPinController.clear();
        return;
      }

      // Save new PIN
      await appLockService.enableAppLock(newPin);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "PIN changed successfully",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Failed to change PIN",
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
          "Change App Lock PIN",
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
                  color: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.password_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Change PIN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter your current PIN and create a new 4-digit PIN.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              // CURRENT PIN
              TextField(
                controller: currentPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "Current PIN",
                  hintText: "Enter current PIN",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),

              const SizedBox(height: 20),

              // NEW PIN
              TextField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "New PIN",
                  hintText: "Enter new 4-digit PIN",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),

              const SizedBox(height: 20),

              // CONFIRM NEW PIN
              TextField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "Confirm New PIN",
                  hintText: "Enter new PIN again",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : _changePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
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
                          "Change PIN",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}