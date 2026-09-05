import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/theme_controller.dart';
import '../utils/app_colors.dart';
import 'app_lock_setup_screen.dart';
import 'app_lock_management_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final AppLockService appLockService =
      AppLockService();

  final ThemeController themeController =
      ThemeController.instance;

  bool isAppLockEnabled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadAppLockStatus();
  }

  // =========================================================
  // LOAD APP LOCK STATUS
  // =========================================================

  Future<void> _loadAppLockStatus() async {
    final enabled =
        await appLockService.isAppLockEnabled();

    if (!mounted) return;

    setState(() {
      isAppLockEnabled = enabled;
      isLoading = false;
    });
  }

  // =========================================================
  // OPEN APP LOCK
  // =========================================================

  Future<void> _openAppLock() async {
    if (isLoading) return;

    // ==========================================
    // APP LOCK NOT ENABLED
    // ==========================================

    if (!isAppLockEnabled) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AppLockSetupScreen(),
        ),
      );

      if (result == true && mounted) {
        await _loadAppLockStatus();
      }

      return;
    }

    // ==========================================
    // APP LOCK ALREADY ENABLED
    // ==========================================

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AppLockManagementScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadAppLockStatus();
    }
  }

  // =========================================================
  // OPEN THEME SELECTOR
  // =========================================================

  Future<void> _openThemeSelector() async {
    final selectedTheme =
        await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 12,
              bottom: 12,
            ),
            child: ValueListenableBuilder<
                ThemeMode>(
              valueListenable:
                  themeController.themeMode,
              builder: (
                context,
                currentThemeMode,
                child,
              ) {
                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    // =========================================
                    // TITLE
                    // =========================================

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          'Choose Theme',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // SYSTEM
                    // =========================================

                    RadioListTile<ThemeMode>(
                      value:
                          ThemeMode.system,
                      groupValue:
                          currentThemeMode,
                      title: const Text(
                        'System default',
                      ),
                      subtitle:
                          const Text(
                        'Use your phone theme',
                      ),
                      secondary:
                          const Icon(
                        Icons
                            .settings_suggest_outlined,
                      ),
                      onChanged:
                          (value) {
                        if (value != null) {
                          Navigator.pop(
                            context,
                            value,
                          );
                        }
                      },
                    ),

                    // =========================================
                    // LIGHT
                    // =========================================

                    RadioListTile<ThemeMode>(
                      value:
                          ThemeMode.light,
                      groupValue:
                          currentThemeMode,
                      title: const Text(
                        'Light',
                      ),
                      subtitle:
                          const Text(
                        'Use light theme',
                      ),
                      secondary:
                          const Icon(
                        Icons
                            .light_mode_outlined,
                      ),
                      onChanged:
                          (value) {
                        if (value != null) {
                          Navigator.pop(
                            context,
                            value,
                          );
                        }
                      },
                    ),

                    // =========================================
                    // DARK
                    // =========================================

                    RadioListTile<ThemeMode>(
                      value:
                          ThemeMode.dark,
                      groupValue:
                          currentThemeMode,
                      title: const Text(
                        'Dark',
                      ),
                      subtitle:
                          const Text(
                        'Use dark theme',
                      ),
                      secondary:
                          const Icon(
                        Icons
                            .dark_mode_outlined,
                      ),
                      onChanged:
                          (value) {
                        if (value != null) {
                          Navigator.pop(
                            context,
                            value,
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    // =========================================================
    // NO SELECTION
    // =========================================================

    if (selectedTheme == null) {
      return;
    }

    // =========================================================
    // SAVE + APPLY THEME
    // =========================================================

    await themeController.setTheme(
      selectedTheme,
    );
  }

  // =========================================================
  // THEME NAME
  // =========================================================

  String _getThemeName() {
    return themeController.currentThemeName;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: ListView(
        children: [
          // =================================================
          // ACCOUNT
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "Account",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.person_outline,
            ),
            title: const Text(
              "Profile",
            ),
            subtitle: const Text(
              "Edit your name, photo and about",
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.phone_outlined,
            ),
            title: const Text(
              "Phone Number",
            ),
            subtitle: const Text(
              "Your registered phone number",
            ),
            onTap: () {},
          ),

          const Divider(),

          // =================================================
          // PRIVACY & SECURITY
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "Privacy & Security",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          // =================================================
          // APP LOCK
          // =================================================

          ListTile(
            leading: const Icon(
              Icons.lock_outline,
            ),
            title: const Text(
              "App Lock",
            ),
            subtitle: Text(
              isLoading
                  ? "Checking App Lock..."
                  : isAppLockEnabled
                      ? "App Lock is enabled"
                      : "Protect NChat with a PIN",
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isAppLockEnabled
                        ? Icons.lock
                        : Icons.lock_open,
                    color:
                        isAppLockEnabled
                            ? AppColors.primary
                            : Colors.grey,
                  ),
            onTap:
                _openAppLock,
          ),

          const Divider(),

          // =================================================
          // NOTIFICATIONS
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "Notifications",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.notifications_none,
            ),
            title: const Text(
              "Message Notifications",
            ),
            subtitle: const Text(
              "New message notifications",
            ),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(
              Icons.call_outlined,
            ),
            title: const Text(
              "Call Notifications",
            ),
            subtitle: const Text(
              "Incoming call notifications",
            ),
            onTap: () {},
          ),

          const Divider(),

          // =================================================
          // CHATS
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "Chats",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
            ),
            title:
                const Text(
              "Chat Settings",
            ),
            subtitle:
                const Text(
              "Manage chat preferences",
            ),
            onTap: () {},
          ),

          const Divider(),

          // =================================================
          // APPEARANCE
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "Appearance",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ValueListenableBuilder<
              ThemeMode>(
            valueListenable:
                themeController.themeMode,
            builder: (
              context,
              currentThemeMode,
              child,
            ) {
              return ListTile(
                leading: const Icon(
                  Icons.palette_outlined,
                ),
                title: const Text(
                  "Theme",
                ),
                subtitle: Text(
                  _getThemeName(),
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap:
                    _openThemeSelector,
              );
            },
          ),

          const Divider(),

          // =================================================
          // ABOUT
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              "About",
              style: TextStyle(
                color:
                    AppColors.primary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.info_outline,
            ),
            title:
                const Text(
              "About NChat",
            ),
            subtitle:
                const Text(
              "Information about NChat",
            ),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(
              Icons.apps,
            ),
            title:
                const Text(
              "Version",
            ),
            subtitle:
                const Text(
              "NChat 1.0.0",
            ),
            onTap: () {},
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}