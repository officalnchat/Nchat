import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ChatController {
  final String receiverId;

  ChatController({
    required this.receiverId,
  });

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  final FirestoreService _firestoreService =
      FirestoreService();

  List<Map<String, dynamic>> messages = [];

  String? currentUserId;

  Future<String> getChatId() async {
    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    final ids = [
      currentUserId!,
      receiverId,
    ]..sort();

    return ids.join("_");
  }

  // ===========================
  // Receiver Presence
  // ===========================

  Stream<DocumentSnapshot> getReceiver() {
    return _firestoreService.getUser(receiverId);
  }

  // ===========================
  // Typing
  // ===========================

  Future<void> setTyping(bool typing) async {
    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    await _firestoreService.setTyping(
      userId: currentUserId!,
      typing: typing,
    );
  }

  // ===========================
  // Messages
  // ===========================

  Stream<QuerySnapshot> getMessages() async* {
    final chatId = await getChatId();

    yield* _firestoreService.getMessages(chatId);
  }

  void loadMessages(QuerySnapshot snapshot) {
    messages = snapshot.docs.map((doc) {
      final data =
          doc.data() as Map<String, dynamic>;

      return {
        "text": data["message"] ?? "",
        "isMe":
            data["senderId"] == currentUserId,
        "time": _formatMessageTime(
          data["timestamp"],
        ),
        "isSeen": data["isSeen"] ?? false,
      };
    }).toList();

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return "";

    final date =
        (timestamp as Timestamp).toDate();

    return _format12Hour(date);
  }

  // ===========================
  // Last Seen
  // ===========================

  String formatLastSeen(dynamic timestamp) {
    if (timestamp == null) {
      return "Offline";
    }

    final date =
        (timestamp as Timestamp).toDate();

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final messageDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(messageDay).inDays;

    if (difference == 0) {
      return "Last seen today at ${_format12Hour(date)}";
    }

    if (difference == 1) {
      return "Last seen yesterday at ${_format12Hour(date)}";
    }

    return "Last seen ${date.day}/${date.month}/${date.year} at ${_format12Hour(date)}";
  }

  String _format12Hour(DateTime date) {
    int hour = date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        hour >= 12 ? "PM" : "AM";

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return "$hour:$minute $period";
  }

  // ===========================
  // Send Message
  // ===========================

  Future<void> sendMessage(
    BuildContext context,
    VoidCallback refresh,
  ) async {
    final text =
        messageController.text.trim();

    if (text.isEmpty) return;

    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    final chatId = await getChatId();

    await _firestoreService.sendMessage(
      chatId: chatId,
      senderId: currentUserId!,
      message: text,
    );

    // Stop Typing
    await setTyping(false);

    messageController.clear();

    refresh();
  }

  void dispose() {
    // Stop Typing while leaving chat
    setTyping(false);

    messageController.dispose();
    scrollController.dispose();
  }
}