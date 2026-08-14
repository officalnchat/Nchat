import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/call_screen.dart';
import '../screens/chat_screen.dart';
import '../main.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AuthService _authService =
      AuthService();

  final FirestoreService _firestoreService =
      FirestoreService();

  // =========================================================
  // PENDING CLOSED-APP NOTIFICATION
  // =========================================================

  RemoteMessage? _pendingInitialMessage;

  // =========================================================
  // INITIALIZE NOTIFICATIONS
  // =========================================================

  Future<void> initialize() async {
    // ---------------------------------------------------------
    // 1. Initialize Local Notifications
    // ---------------------------------------------------------

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTap,
    );

    // ---------------------------------------------------------
    // 2. Android Notification Channel
    // ---------------------------------------------------------

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'nchat_notifications',
      'NChat Notifications',
      description:
          'Notifications for NChat messages and calls',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          channel,
        );

    // ---------------------------------------------------------
    // 3. Request FCM Permission
    // ---------------------------------------------------------

    final settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      '🔔 Notification permission: '
      '${settings.authorizationStatus}',
    );

    // ---------------------------------------------------------
    // 4. Get FCM Token
    // ---------------------------------------------------------

    final token =
        await _messaging.getToken();

    debugPrint(
      '🔥 FCM TOKEN: $token',
    );

    // ---------------------------------------------------------
    // 5. Save FCM Token
    // ---------------------------------------------------------

    if (token != null &&
        token.isNotEmpty) {
      await _saveTokenToFirestore(
        token,
      );
    }

    // ---------------------------------------------------------
    // 6. Token Refresh
    // ---------------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        debugPrint(
          '🔄 FCM TOKEN REFRESHED: $newToken',
        );

        await _saveTokenToFirestore(
          newToken,
        );
      },
    );

    // ---------------------------------------------------------
    // 7. Foreground Message
    // ---------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint(
          '📩 Foreground notification received',
        );

        debugPrint(
          'Title: '
          '${message.notification?.title}',
        );

        debugPrint(
          'Body: '
          '${message.notification?.body}',
        );

        debugPrint(
          'Data: ${message.data}',
        );

        await _showForegroundNotification(
          message,
        );
      },
    );

    // ---------------------------------------------------------
    // 8. Background Notification Tap
    // ---------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint(
          '👆 Notification tapped from background',
        );

        debugPrint(
          'Data: ${message.data}',
        );

        _handleNotificationTap(
          message,
        );
      },
    );

    // ---------------------------------------------------------
    // 9. Completely Closed App
    // ---------------------------------------------------------

    final initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        '🚀 App opened from notification',
      );

      debugPrint(
        'Data: ${initialMessage.data}',
      );

      // IMPORTANT:
      // Do NOT navigate here because main.dart has
      // not called runApp() yet.

      _pendingInitialMessage =
          initialMessage;
    }
  }

  // =========================================================
  // HANDLE PENDING CLOSED-APP NOTIFICATION
  // =========================================================

  void handlePendingInitialNotification() {
    final message =
        _pendingInitialMessage;

    if (message == null) {
      return;
    }

    _pendingInitialMessage = null;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _handleNotificationTap(
          message,
        );
      },
    );
  }

  // =========================================================
  // SAVE TOKEN
  // =========================================================

  Future<void> _saveTokenToFirestore(
    String token,
  ) async {
    try {
      final userId =
          await _authService.getUserId();

      if (userId.isEmpty) {
        debugPrint(
          '❌ FCM: User ID not available',
        );
        return;
      }

      await _firestoreService.saveFcmToken(
        userId: userId,
        token: token,
      );

      debugPrint(
        '✅ FCM token saved to Firestore',
      );
    } catch (e) {
      debugPrint(
        '❌ FCM token save error: $e',
      );
    }
  }

  // =========================================================
  // SHOW FOREGROUND NOTIFICATION
  // =========================================================

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification =
        message.notification;

    final title =
        notification?.title ??
            message.data['title'] ??
            'NChat';

    final body =
        notification?.body ??
            message.data['body'] ??
            'New notification';

    await _localNotifications.show(
      DateTime.now()
          .millisecondsSinceEpoch
          .remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nchat_notifications',
          'NChat Notifications',
          channelDescription:
              'Notifications for NChat messages and calls',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload:
          _createPayload(
        message.data,
      ),
    );
  }

  // =========================================================
  // CREATE PAYLOAD
  // =========================================================

  String _createPayload(
    Map<String, dynamic> data,
  ) {
    final type =
        data['type'] ?? '';

    final chatId =
        data['chatId'] ?? '';

    final callId =
        data['callId'] ?? '';

    final receiverId =
        data['receiverId'] ?? '';

    final senderId =
        data['senderId'] ?? '';

    final userName =
        data['userName'] ?? '';

    return '$type|'
        '$chatId|'
        '$callId|'
        '$receiverId|'
        '$senderId|'
        '$userName';
  }

  // =========================================================
  // LOCAL NOTIFICATION TAP
  // =========================================================

  void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    final payload =
        response.payload;

    if (payload == null ||
        payload.isEmpty) {
      debugPrint(
        '❌ Notification payload missing',
      );
      return;
    }

    final parts =
        payload.split('|');

    if (parts.isEmpty) {
      return;
    }

    final type =
        parts.isNotEmpty
            ? parts[0]
            : '';

    final chatId =
        parts.length > 1
            ? parts[1]
            : '';

    final callId =
        parts.length > 2
            ? parts[2]
            : '';

    final receiverId =
        parts.length > 3
            ? parts[3]
            : '';

    final senderId =
        parts.length > 4
            ? parts[4]
            : '';

    final userName =
        parts.length > 5
            ? parts[5]
            : '';

    _navigateFromNotification(
      type: type,
      chatId: chatId,
      callId: callId,
      receiverId: receiverId,
      senderId: senderId,
      userName: userName,
    );
  }

  // =========================================================
  // FIREBASE NOTIFICATION TAP
  // =========================================================

  void _handleNotificationTap(
    RemoteMessage message,
  ) {
    final data =
        message.data;

    final type =
        data['type'] ?? '';

    final chatId =
        data['chatId'] ?? '';

    final callId =
        data['callId'] ?? '';

    final receiverId =
        data['receiverId'] ?? '';

    final senderId =
        data['senderId'] ?? '';

    final userName =
        data['userName'] ?? '';

    _navigateFromNotification(
      type: type,
      chatId: chatId,
      callId: callId,
      receiverId: receiverId,
      senderId: senderId,
      userName: userName,
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _navigateFromNotification({
    required String type,
    required String chatId,
    required String callId,
    required String receiverId,
    required String senderId,
    required String userName,
  }) {
    final navigator =
        MyApp.navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        '❌ Navigator not ready',
      );
      return;
    }

    // -------------------------------------------------------
    // MESSAGE NOTIFICATION
    // -------------------------------------------------------

    if (type == 'message') {
      if (senderId.isEmpty) {
        debugPrint(
          '❌ Message notification: senderId missing',
        );
        return;
      }

      debugPrint(
        '📩 Opening ChatScreen',
      );

      debugPrint(
        '👤 Sender ID: $senderId',
      );

      debugPrint(
        '👤 Sender Name: $userName',
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            userName:
                userName.isNotEmpty
                    ? userName
                    : 'Chat',
            receiverId:
                senderId,
          ),
        ),
      );

      return;
    }

    // -------------------------------------------------------
    // VOICE CALL NOTIFICATION
    // -------------------------------------------------------

    if (type == 'call') {
      if (senderId.isEmpty ||
          callId.isEmpty) {
        debugPrint(
          '❌ Call notification data missing',
        );
        return;
      }

      debugPrint(
        '📞 Opening CallScreen',
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            userName:
                userName.isNotEmpty
                    ? userName
                    : 'NChat Call',
            photoUrl: '',
            receiverId:
                senderId,
            isIncoming: true,
            callId: callId,
          ),
        ),
      );

      return;
    }

    debugPrint(
      '⚠️ Unknown notification type: $type',
    );
  }
}