import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();

  CollectionReference get usersCollection =>
      _firestore.collection('users');

  CollectionReference get chatsCollection =>
      _firestore.collection('chats');

  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final Reference ref = _storage
        .ref()
        .child("profile_images")
        .child("$userId.jpg");

    await ref.putFile(imageFile);

    return await ref.getDownloadURL();
  }

  Future<void> saveUser({
    required String userId,
    required String name,
    required String about,
    String? photoUrl,
  }) async {
    await usersCollection.doc(userId).set({
      "userId": userId,
      "name": name,
      "about": about,
      "photoUrl": photoUrl ?? "",
      "createdAt": FieldValue.serverTimestamp(),

      // Presence
      "isOnline": false,
      "lastSeen": FieldValue.serverTimestamp(),
      "isTyping": false,
    });
  }

  Future<String> getCurrentUserId() async {
    return await _authService.getUserId();
  }

  Stream<QuerySnapshot> getUsers() {
    return usersCollection
        .orderBy("createdAt")
        .snapshots();
  }

  Stream<DocumentSnapshot> getUser(String userId) {
    return usersCollection
        .doc(userId)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": senderId,
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "isSeen": false,
      "type": "text",
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return chatsCollection
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots();
  }

  // ===========================
  // Presence
  // ===========================

  Future<void> setUserOnline(String userId) async {
    await usersCollection.doc(userId).update({
      "isOnline": true,
      "lastSeen": FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserOffline(String userId) async {
    await usersCollection.doc(userId).update({
      "isOnline": false,
      "lastSeen": FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTyping({
    required String userId,
    required bool typing,
  }) async {
    await usersCollection.doc(userId).update({
      "isTyping": typing,
    });
  }
}