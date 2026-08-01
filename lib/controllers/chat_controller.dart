import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

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

  final StorageService _storageService =
      StorageService();

  List<Map<String, dynamic>> messages = [];
  
  // ===========================
// Search
// ===========================

final TextEditingController searchController =
    TextEditingController();

List<Map<String, dynamic>> filteredMessages = [];

bool isSearching = false;

// ===========================
// Reply
// ===========================

Map<String, dynamic>? replyMessage;

void setReplyMessage(
  Map<String, dynamic> message,
) {
  replyMessage = message;
}

void clearReplyMessage() {
  replyMessage = null;
}

// ===========================
// Forward
// ===========================

Map<String, dynamic>? forwardMessage;

void setForwardMessage(
  Map<String, dynamic> message,
) {
  forwardMessage = message;
}

void clearForwardMessage() {
  forwardMessage = null;
}

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
    return _firestoreService.getUser(
      receiverId,
    );
  }

  // ===========================
  // Typing
  // ===========================

  Future<void> setTyping(
    bool typing,
  ) async {
    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    await _firestoreService.setTyping(
      userId: currentUserId!,
      typing: typing,
    );
  }

  // ===========================
  // Messages Stream
  // ===========================

  Stream<QuerySnapshot> getMessages() async* {
    final chatId = await getChatId();

    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    yield* _firestoreService.getMessages(
      chatId,
    );
  }

  // ===========================
  // Update Message Status
  // ===========================

  Future<void> updateMessageStatus() async {
    final chatId = await getChatId();

    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    await _firestoreService.markMessagesDelivered(
      chatId: chatId,
      currentUserId: currentUserId!,
    );

    await _firestoreService.markMessagesSeen(
      chatId: chatId,
      currentUserId: currentUserId!,
    );
  }

  // ===========================
  // Load Messages
  // ===========================

  void loadMessages(
    QuerySnapshot snapshot,
  ) {
    messages = snapshot.docs
    .map((doc) {
      final data =
          doc.data() as Map<String, dynamic>;

      if ((data["deletedFor"] ?? [])
          .contains(currentUserId)) {
        return null;
      }

      return {
        "docId": doc.id,
        "text": data["message"] ?? "",
        "imageUrl": data["imageUrl"] ?? "",
        "type": data["type"] ?? "text",
        "isMe":
            data["senderId"] == currentUserId,
        "time":
            _formatMessageTime(
          data["timestamp"],
        ),
        "status":
            data["status"] ?? 1,

            "isStarred":
    data["isStarred"] ?? false,

          "forwarded":
    data["forwarded"] ?? "",

    "reaction":
    data["reaction"] ?? "",

    "replyMessage":
            data["replyMessage"] ?? "",

        "replyType":
            data["replyType"] ?? "",
      };
    })
    .whereType<Map<String, dynamic>>()
    .toList();
    
    filteredMessages = List.from(messages);

    Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
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

  String _formatMessageTime(
    dynamic timestamp,
  ) {
    if (timestamp == null) return "";

    final date =
        (timestamp as Timestamp).toDate();

    return _format12Hour(date);
  }
  // ===========================
// Search Messages
// ===========================

void searchMessages(String query) {
  if (query.trim().isEmpty) {
    filteredMessages = List.from(messages);
    return;
  }

  filteredMessages = messages.where((message) {
    final text =
        message["text"].toString().toLowerCase();

    return text.contains(
      query.toLowerCase(),
    );
  }).toList();
}
    // ===========================
  // Last Seen
  // ===========================

  String formatLastSeen(
    dynamic timestamp,
  ) {
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

  String _format12Hour(
    DateTime date,
  ) {
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

        print("STEP 1");

    if (text.isEmpty) return;

    currentUserId ??=
        await _firestoreService.getCurrentUserId();

        print("STEP 2");

    final chatId =
        await getChatId();

        print("STEP 3 - ChatId: $chatId");

  if (forwardMessage != null) {
    print("STEP 4 - About to call FirestoreService.sendMessage()");

  await _firestoreService.sendMessage(
    chatId: chatId,
    senderId: currentUserId!,
    receiverId: receiverId,
    message: forwardMessage!["text"],

    forwarded: "true",
  );
  print("STEP 5 - FirestoreService.sendMessage() completed");

  await setTyping(false);

  messageController.clear();

  clearForwardMessage();

  refresh();

  return;
}
   await _firestoreService.sendMessage(
  chatId: chatId,
  senderId: currentUserId!,
  receiverId: receiverId,
  message: text,

  replyMessage:
      replyMessage?["text"],

  replyType:
      replyMessage?["type"],

      forwarded: "",
);

   await setTyping(false);

messageController.clear();

clearReplyMessage();

refresh();
  }
    // ===========================
  // Send Image
  // ===========================

  Future<void> sendImage(
    BuildContext context,
    VoidCallback refresh,
  ) async {
    final File? image =
        await _storageService.pickImage();

    if (image == null) {
      return;
    }

    currentUserId ??=
        await _firestoreService.getCurrentUserId();

    final chatId =
        await getChatId();

    final String? imageUrl =
        await _storageService.uploadChatImage(
      imageFile: image,
      chatId: chatId,
    );

    if (imageUrl == null) {
      return;
    }

    await _firestoreService.sendImageMessage(
  chatId: chatId,
  senderId: currentUserId!,
  receiverId: receiverId,
  imageUrl: imageUrl,

  replyMessage:
      replyMessage?["text"],

  replyType:
      replyMessage?["type"],

      forwarded: "",
);

  await setTyping(false);

clearReplyMessage();

refresh();
  }

  // ===========================
// Delete Message
// ===========================

Future<void> deleteMessage(
  String docId,
) async {
  final chatId = await getChatId();

  await _firestoreService.deleteMessage(
    chatId: chatId,
    messageId: docId,
  );
}

// ===========================
// Delete For Me
// ===========================

Future<void> deleteMessageForMe(
  String docId,
) async {
  final chatId = await getChatId();

  currentUserId ??=
      await _firestoreService.getCurrentUserId();

  await _firestoreService.deleteMessageForMe(
    chatId: chatId,
    messageId: docId,
    userId: currentUserId!,
  );
}

// ===========================
// Star / Unstar Message
// ===========================

Future<void> toggleStarMessage(
  String docId,
  bool isStarred,
) async {
  final chatId = await getChatId();

  await _firestoreService.toggleStarMessage(
    chatId: chatId,
    messageId: docId,
    isStarred: isStarred,
  );
}

// ===========================
// Message Reaction
// ===========================

Future<void> setReaction(
  String docId,
  String emoji,
) async {
  final chatId = await getChatId();

  await _firestoreService.setReaction(
    chatId: chatId,
    messageId: docId,
    emoji: emoji,
  );
}


// ===========================
// Dispose
// ===========================

void dispose() {
  setTyping(false);

  messageController.dispose();

  scrollController.dispose();

  searchController.dispose();
}
}