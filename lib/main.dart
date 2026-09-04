import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'utils/app_theme.dart';
import 'widgets/app_lifecycle_handler.dart';

// =========================================================
// FIREBASE MESSAGING BACKGROUND HANDLER
// =========================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'FCM background message: ${message.messageId}',
  );

  debugPrint(
    'FCM background data: ${message.data}',
  );
}

// =========================================================
// MAIN
// =========================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------
  // Firebase
  // ---------------------------------------------------------

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ---------------------------------------------------------
  // Background FCM handler
  // ---------------------------------------------------------

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // ---------------------------------------------------------
  // Notification Service
  // ---------------------------------------------------------

  final notificationService = NotificationService();

  await notificationService.initialize();

  // ---------------------------------------------------------
  // Theme Service
  // ---------------------------------------------------------

  final themeService = ThemeService();

  final themeModeString =
      await themeService.getThemeMode();

  // ---------------------------------------------------------
  // Convert saved string to ThemeMode
  // ---------------------------------------------------------

  ThemeMode themeMode;

  switch (themeModeString) {
    case 'dark':
      themeMode = ThemeMode.dark;
      break;

    case 'light':
      themeMode = ThemeMode.light;
      break;

    case 'system':
    default:
      themeMode = ThemeMode.system;
      break;
  }

  // ---------------------------------------------------------
  // Start App
  // ---------------------------------------------------------

  runApp(
    MyApp(
      themeMode: themeMode,
    ),
  );

  // ---------------------------------------------------------
  // Handle notification that opened the completely
  // closed application.
  // ---------------------------------------------------------

  notificationService.handlePendingInitialNotification();
}

// =========================================================
// MY APP
// =========================================================

class MyApp extends StatefulWidget {
  final ThemeMode themeMode;

  const MyApp({
    super.key,
    required this.themeMode,
  });

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

// =========================================================
// MY APP STATE
// =========================================================

class _MyAppState extends State<MyApp> {
  late ThemeMode themeMode;

  @override
  void initState() {
    super.initState();

    themeMode = widget.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleHandler(
      navigatorKey: MyApp.navigatorKey,
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'NChat',

        // -----------------------------------------------------
        // Themes
        // -----------------------------------------------------

        theme: AppTheme.lightTheme,

        darkTheme: AppTheme.darkTheme,

        themeMode: themeMode,

        // -----------------------------------------------------
        // Home
        // -----------------------------------------------------

        home: const SplashScreen(),
      ),
    );
  }
}