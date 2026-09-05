import 'package:flutter/material.dart';

import 'theme_service.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance =
      ThemeController._();

  final ThemeService _themeService =
      ThemeService();

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> initialize() async {
    final savedTheme =
        await _themeService.getThemeMode();

    switch (savedTheme) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;

      case 'light':
        themeMode.value = ThemeMode.light;
        break;

      case 'system':
      default:
        themeMode.value = ThemeMode.system;
        break;
    }
  }

  // =========================================================
  // CHANGE THEME
  // =========================================================

  Future<void> setTheme(
    ThemeMode newThemeMode,
  ) async {
    String themeModeString;

    switch (newThemeMode) {
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;

      case ThemeMode.light:
        themeModeString = 'light';
        break;

      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }

    await _themeService.saveThemeMode(
      themeModeString,
    );

    themeMode.value = newThemeMode;
  }

  // =========================================================
  // CURRENT THEME NAME
  // =========================================================

  String get currentThemeName {
    switch (themeMode.value) {
      case ThemeMode.dark:
        return 'Dark theme';

      case ThemeMode.light:
        return 'Light theme';

      case ThemeMode.system:
        return 'System default';
    }
  }
}