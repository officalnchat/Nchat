import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/app_colors.dart';
import 'app_lock_setup_screen.dart';
import 'app_lock_management_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final AppLockService appLockService =
      AppLockService();

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
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
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
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "Account",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "Privacy & Security",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // =================================================
          // APP LOCK
          // =================================================

          ListTile(
            leading:
                const Icon(Icons.lock_outline),
            title:
                const Text("App Lock"),
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
            onTap: _openAppLock,
          ),

          const Divider(),

          // =================================================
          // NOTIFICATIONS
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "Notifications",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
            leading:
                const Icon(Icons.call_outlined),
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
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "Chats",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
            ),
            title:
                const Text("Chat Settings"),
            subtitle: const Text(
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
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "Appearance",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading:
                const Icon(Icons.palette_outlined),
            title: const Text("Theme"),
            subtitle: const Text(
              "NChat appearance",
            ),
            onTap: () {},
          ),

          const Divider(),

          // =================================================
          // ABOUT
          // =================================================

          const Padding(
            padding:
                EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "About",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading:
                const Icon(Icons.info_outline),
            title:
                const Text("About NChat"),
            subtitle: const Text(
              "Information about NChat",
            ),
            onTap: () {},
          ),

          ListTile(
            leading:
                const Icon(Icons.apps),
            title: const Text("Version"),
            subtitle:
                const Text("NChat 1.0.0"),
            onTap: () {},
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}