import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  // =========================================================
  // SAVE THEME
  // =========================================================

  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      themeMode,
    );
  }

  // =========================================================
  // GET THEME
  // =========================================================

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeKey) ?? 'system';
  }
}