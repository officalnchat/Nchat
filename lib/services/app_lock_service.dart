import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const String _appLockEnabledKey =
      'app_lock_enabled';

  static const String _appLockPinKey =
      'app_lock_pin';

  static const String _failedAttemptsKey =
      'app_lock_failed_attempts';

  static const String _lockoutUntilKey =
      'app_lock_lockout_until';

  static const String _securityQuestion1Key =
      'app_lock_security_question_1';

  static const String _securityAnswer1Key =
      'app_lock_security_answer_1';

  static const String _securityQuestion2Key =
      'app_lock_security_question_2';

  static const String _securityAnswer2Key =
      'app_lock_security_answer_2';

  // =========================================================
  // APP LOCK ENABLED
  // =========================================================

  Future<bool> isAppLockEnabled() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  // =========================================================
  // ENABLE APP LOCK
  // =========================================================

  Future<void> enableAppLock(String pin) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _appLockPinKey,
      pin,
    );

    await prefs.setBool(
      _appLockEnabledKey,
      true,
    );

    await resetFailedAttempts();
  }

  // =========================================================
  // DISABLE APP LOCK
  // =========================================================

  Future<void> disableAppLock() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _appLockEnabledKey,
      false,
    );

    await prefs.remove(
      _appLockPinKey,
    );

    await prefs.remove(
      _securityQuestion1Key,
    );

    await prefs.remove(
      _securityAnswer1Key,
    );

    await prefs.remove(
      _securityQuestion2Key,
    );

    await prefs.remove(
      _securityAnswer2Key,
    );

    await resetFailedAttempts();
  }

  // =========================================================
  // VERIFY PIN
  // =========================================================

  Future<bool> verifyPin(String pin) async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedPin =
        prefs.getString(_appLockPinKey);

    if (savedPin == null) {
      return false;
    }

    return savedPin == pin;
  }

  // =========================================================
  // PIN EXISTS
  // =========================================================

  Future<bool> hasPin() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
          _appLockPinKey,
        ) !=
        null;
  }

  // =========================================================
  // FAILED ATTEMPTS
  // =========================================================

  Future<int> getFailedAttempts() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
          _failedAttemptsKey,
        ) ??
        0;
  }

  // =========================================================
  // LOCKOUT CHECK
  // =========================================================

  Future<bool> isLockedOut() async {
    final prefs =
        await SharedPreferences.getInstance();

    final lockoutUntil =
        prefs.getInt(
      _lockoutUntilKey,
    );

    if (lockoutUntil == null) {
      return false;
    }

    final now =
        DateTime.now().millisecondsSinceEpoch;

    if (now >= lockoutUntil) {
      await prefs.remove(
        _lockoutUntilKey,
      );

      return false;
    }

    return true;
  }

  // =========================================================
  // REMAINING LOCK TIME
  // =========================================================

  Future<Duration> getRemainingLockTime() async {
    final prefs =
        await SharedPreferences.getInstance();

    final lockoutUntil =
        prefs.getInt(
      _lockoutUntilKey,
    );

    if (lockoutUntil == null) {
      return Duration.zero;
    }

    final now =
        DateTime.now().millisecondsSinceEpoch;

    final difference =
        lockoutUntil - now;

    if (difference <= 0) {
      await prefs.remove(
        _lockoutUntilKey,
      );

      return Duration.zero;
    }

    return Duration(
      milliseconds: difference,
    );
  }

  // =========================================================
  // RECORD FAILED PIN ATTEMPT
  // =========================================================

  Future<Duration> recordFailedAttempt() async {
    final prefs =
        await SharedPreferences.getInstance();

    int attempts =
        prefs.getInt(
              _failedAttemptsKey,
            ) ??
            0;

    attempts++;

    await prefs.setInt(
      _failedAttemptsKey,
      attempts,
    );

    Duration lockDuration =
        Duration.zero;

    if (attempts >= 4) {
      final lockSeconds =
          _calculateLockSeconds(
        attempts,
      );

      lockDuration =
          Duration(
        seconds: lockSeconds,
      );

      final lockoutUntil =
          DateTime.now()
                  .add(lockDuration)
                  .millisecondsSinceEpoch;

      await prefs.setInt(
        _lockoutUntilKey,
        lockoutUntil,
      );
    }

    return lockDuration;
  }

  // =========================================================
  // LOCKOUT CALCULATION
  // =========================================================

  int _calculateLockSeconds(
    int attempts,
  ) {
    if (attempts == 4) {
      return 30;
    }

    if (attempts == 5) {
      return 60;
    }

    if (attempts == 6) {
      return 120;
    }

    if (attempts == 7) {
      return 240;
    }

    if (attempts == 8) {
      return 480;
    }

    return 900;
  }

  // =========================================================
  // RESET FAILED ATTEMPTS
  // =========================================================

  Future<void> resetFailedAttempts() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _failedAttemptsKey,
    );

    await prefs.remove(
      _lockoutUntilKey,
    );
  }

  // =========================================================
  // SECURITY QUESTIONS
  // =========================================================

  Future<void> saveSecurityQuestions({
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _securityQuestion1Key,
      question1,
    );

    await prefs.setString(
      _securityAnswer1Key,
      answer1.trim().toLowerCase(),
    );

    await prefs.setString(
      _securityQuestion2Key,
      question2,
    );

    await prefs.setString(
      _securityAnswer2Key,
      answer2.trim().toLowerCase(),
    );
  }

  // =========================================================
  // GET SECURITY QUESTIONS
  // =========================================================

  Future<String?> getSecurityQuestion1() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _securityQuestion1Key,
    );
  }

  Future<String?> getSecurityQuestion2() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _securityQuestion2Key,
    );
  }

  // =========================================================
  // VERIFY SECURITY ANSWERS
  // =========================================================

  Future<bool> verifySecurityAnswers({
    required String answer1,
    required String answer2,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedAnswer1 =
        prefs.getString(
      _securityAnswer1Key,
    );

    final savedAnswer2 =
        prefs.getString(
      _securityAnswer2Key,
    );

    if (savedAnswer1 == null ||
        savedAnswer2 == null) {
      return false;
    }

    final inputAnswer1 =
        answer1.trim().toLowerCase();

    final inputAnswer2 =
        answer2.trim().toLowerCase();

    return savedAnswer1 == inputAnswer1 &&
        savedAnswer2 == inputAnswer2;
  }

  // =========================================================
  // SECURITY QUESTIONS EXIST
  // =========================================================

  Future<bool> hasSecurityQuestions() async {
    final prefs =
        await SharedPreferences.getInstance();

    final question1 =
        prefs.getString(
      _securityQuestion1Key,
    );

    final question2 =
        prefs.getString(
      _securityQuestion2Key,
    );

    return question1 != null &&
        question2 != null;
  }

  // =========================================================
  // CLEAR ONLY APP LOCK DATA
  // =========================================================
  //
  // IMPORTANT:
  // This does NOT delete chats.
  // This does NOT delete Firestore data.
  // This does NOT delete the user's account.
  //
  // =========================================================

  Future<void> clearAppLockData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _appLockEnabledKey,
    );

    await prefs.remove(
      _appLockPinKey,
    );

    await prefs.remove(
      _failedAttemptsKey,
    );

    await prefs.remove(
      _lockoutUntilKey,
    );

    await prefs.remove(
      _securityQuestion1Key,
    );

    await prefs.remove(
      _securityAnswer1Key,
    );

    await prefs.remove(
      _securityQuestion2Key,
    );

    await prefs.remove(
      _securityAnswer2Key,
    );
  }
}