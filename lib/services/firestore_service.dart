import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final AuthService _authService =
      AuthService();

  CollectionReference get usersCollection =>
      _firestore.collection('users');

  CollectionReference get chatsCollection =>
      _firestore.collection('chats');

  // ===========================
  // Profile Image
  // ===========================

  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final Reference ref = _storage
        .ref()
        .child('profile_images')
        .child('$userId.jpg');

    await ref.putFile(imageFile);

    return await ref.getDownloadURL();
  }

  // ===========================
  // Save User
  // ===========================

  Future<void> saveUser({
    required String userId,
    required String name,
    required String about,
    String? photoUrl,
  }) async {
    await usersCollection.doc(userId).set({
      'userId': userId,
      'name': name,
      'about': about,
      'photoUrl': photoUrl ?? '',
      'createdAt':
          FieldValue.serverTimestamp(),

      // Presence
      'isOnline': false,
      'lastSeen':
          FieldValue.serverTimestamp(),
      'isTyping': false,
    });
  }

  Future<String> getCurrentUserId() async {
    return await _authService.getUserId();
  }

  Stream<QuerySnapshot> getUsers() {
    return usersCollection
        .orderBy('createdAt')
        .snapshots();
  }

  Stream<DocumentSnapshot> getUser(
    String userId,
  ) {
    return usersCollection
        .doc(userId)
        .snapshots();
  }

  // ===========================
  // Send Text Message
  // ===========================

 Future<void> sendMessage({
  required String chatId,
  required String senderId,
  required String receiverId,
  required String message,

  String? replyMessage,
  String? replyType,
})
  async {
    await chatsCollection
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'imageUrl': '',
      'timestamp':
          FieldValue.serverTimestamp(),

      // 1 = Sent
      // 2 = Delivered
      // 3 = Seen
      'status': 1,

      'type': 'text',
      
      'replyMessage': replyMessage ?? '',
'replyType': replyType ?? '',
    });
  }

  // ===========================
  // Send Image Message
  // ===========================

  Future<void> sendImageMessage({
  required String chatId,
  required String senderId,
  required String receiverId,
  required String imageUrl,

  String? replyMessage,
  String? replyType,
}) async {
    await chatsCollection
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,

      // No text for image messages
      'message': '',

      // Image URL
      'imageUrl': imageUrl,

      'timestamp':
          FieldValue.serverTimestamp(),

      // 1 = Sent
      // 2 = Delivered
      // 3 = Seen
      'status': 1,

      'type': 'image',

      'replyMessage': replyMessage ?? '',
'replyType': replyType ?? '',
    });
  }

  // ===========================
  // Messages Stream
  // ===========================

  Stream<QuerySnapshot> getMessages(
    String chatId,
  ) {
    return chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // ===========================
  // Delivered
  // ===========================

  Future<void> markMessagesDelivered({
    required String chatId,
    required String currentUserId,
  }) async {
    final snapshot = await chatsCollection
        .doc(chatId)
        .collection('messages')
        .where(
          'receiverId',
          isEqualTo: currentUserId,
        )
        .where(
          'status',
          isEqualTo: 1,
        )
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'status': 2,
      });
    }
  }

  // ===========================
  // Seen
  // ===========================

  Future<void> markMessagesSeen({
    required String chatId,
    required String currentUserId,
  }) async {
    final snapshot = await chatsCollection
        .doc(chatId)
        .collection('messages')
        .where(
          'receiverId',
          isEqualTo: currentUserId,
        )
        .where(
          'status',
          isEqualTo: 2,
        )
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'status': 3,
      });
    }
  }

  // ===========================
  // Presence
  // ===========================

  Future<void> setUserOnline(
    String userId,
  ) async {
    await usersCollection.doc(userId).update({
      'isOnline': true,
      'lastSeen':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserOffline(
    String userId,
  ) async {
    await usersCollection.doc(userId).update({
      'isOnline': false,
      'lastSeen':
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================
  // Typing
  // ===========================

  Future<void> setTyping({
    required String userId,
    required bool typing,
  }) async {
    await usersCollection.doc(userId).update({
      'isTyping': typing,
    });
  }
  // ===========================
// Delete Message
// ===========================

Future<void> deleteMessage({
  required String chatId,
  required String messageId,
}) async {
  await chatsCollection
      .doc(chatId)
      .collection("messages")
      .doc(messageId)
      .delete();
}
}