import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
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
// Start App
// ---------------------------------------------------------

runApp(
  const MyApp(),
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

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AppLifecycleHandler(
      navigatorKey: navigatorKey,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'NChat',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}