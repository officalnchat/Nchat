import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const String _userIdKey = "user_id";
  static const String _isLoggedInKey = "is_logged_in";

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  // Login Complete
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  // Check Login Status
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout (Future Use)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_isLoggedInKey);

    // User ID remove nahi kar rahe.
    // Future me Firebase Auth aane par
    // yahan signOut() bhi add karenge.
  }
}