import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'auth_service.dart';
import 'cloudinary_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final CloudinaryService _cloudinaryService =
      CloudinaryService();

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
    final String? imageUrl =
        await _cloudinaryService.uploadImage(
      imageFile,
    );

    return imageUrl ?? "";
  }

  // ===========================
  // Save User
  // ===========================

  Future<void> saveUser({
    required String userId,
    required String phoneNumber,
    required String name,
    required String about,
    String? photoUrl,
  }) async {
    await usersCollection.doc(userId).set({
      'userId': userId,
      'phoneNumber': phoneNumber,
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

  // ===========================
  // FCM Token
  // ===========================

  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    await usersCollection.doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  // ===========================
  // Get Users
  // ===========================

  Stream<QuerySnapshot> getUsers() {
    return usersCollection
        .orderBy('createdAt')
        .snapshots();
  }

  // ===========================
  // Get NChat Users From Contacts
  // ===========================

  Future<List<Map<String, dynamic>>>
      getUsersFromContacts({
    required List<String> phoneNumbers,
    required String currentUserId,
  }) async {
    if (phoneNumbers.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> users = [];

    // Firestore whereIn has a limit on the
    // number of values in a single query.
    // Therefore contacts are processed in batches.
    const int batchSize = 30;

    for (
      int i = 0;
      i < phoneNumbers.length;
      i += batchSize
    ) {
      final int end =
          (i + batchSize < phoneNumbers.length)
              ? i + batchSize
              : phoneNumbers.length;

      final List<String> batch =
          phoneNumbers.sublist(i, end);

      final QuerySnapshot snapshot =
          await usersCollection
              .where(
                'phoneNumber',
                whereIn: batch,
              )
              .get();

      for (final doc in snapshot.docs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final String userId =
            data['userId']?.toString() ?? '';

        // Never show the current user.
        if (userId.isEmpty ||
            userId == currentUserId) {
          continue;
        }

        users.add(data);
      }
    }

    // Remove duplicate users.
    final Map<String, Map<String, dynamic>>
        uniqueUsers = {};

    for (final user in users) {
      final String userId =
          user['userId']?.toString() ?? '';

      if (userId.isNotEmpty) {
        uniqueUsers[userId] = user;
      }
    }

    return uniqueUsers.values.toList();
  }

  // ===========================
  // Get User
  // ===========================

  Stream<DocumentSnapshot> getUser(
    String userId,
  ) {
    return usersCollection
        .doc(userId)
        .snapshots();
  }

  // ===========================
  // Update Profile
  // ===========================

  Future<void> updateProfile({
    required String userId,
    required String name,
    required String about,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'about': about,
    };

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    await usersCollection
        .doc(userId)
        .update(data);
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
    String? forwarded,
  }) async {
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

      'isStarred': false,

      'replyMessage':
          replyMessage ?? '',
      'replyType':
          replyType ?? '',

      'forwarded':
          forwarded ?? '',
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
    String? caption,
    String? replyMessage,
    String? replyType,
    String? forwarded,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': caption ?? '',
      'imageUrl': imageUrl,
      'timestamp':
          FieldValue.serverTimestamp(),

      // 1 = Sent
      // 2 = Delivered
      // 3 = Seen
      'status': 1,

      'type': 'image',

      'isStarred': false,

      'replyMessage':
          replyMessage ?? '',
      'replyType':
          replyType ?? '',

      'forwarded':
          forwarded ?? '',
    });
  }

  // ===========================
  // Send Voice Message
  // ===========================

  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String audioUrl,
    String? replyMessage,
    String? replyType,
    String? forwarded,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": senderId,
      "receiverId": receiverId,
      "message": "",
      "imageUrl": "",
      "audioUrl": audioUrl,
      "type": "audio",
      "timestamp":
          FieldValue.serverTimestamp(),
      "status": 1,
      "isStarred": false,
      "forwarded":
          forwarded ?? "",
      "reaction": "",
      "replyMessage":
          replyMessage ?? "",
      "replyType":
          replyType ?? "",
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

  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "deletedFor":
          FieldValue.arrayUnion([
        userId,
      ]),
    });
  }

  // ===========================
  // Star / Unstar Message
  // ===========================

  Future<void> toggleStarMessage({
    required String chatId,
    required String messageId,
    required bool isStarred,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "isStarred": !isStarred,
    });
  }

  // ===========================
  // Message Reaction
  // ===========================

  Future<void> setReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    await chatsCollection
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "reaction": emoji,
    });
  }

  // ===========================
  // Call Id
  // ===========================

  String getCallId({
    required String user1,
    required String user2,
  }) {
    final ids = [
      user1,
      user2,
    ]..sort();

    return ids.join("_");
  }

  // ===========================
  // Start Voice Call
  // ===========================

  Future<String> startVoiceCall({
    required String callerId,
    required String receiverId,
  }) async {
    final callId = getCallId(
      user1: callerId,
      user2: receiverId,
    );

    await _firestore
        .collection("calls")
        .doc(callId)
        .set({
      "callId": callId,
      "callerId": callerId,
      "receiverId": receiverId,
      "type": "voice",
      "status": "calling",
      "createdAt":
          FieldValue.serverTimestamp(),
      "acceptedAt": null,
      "endedAt": null,
    });

    return callId;
  }

  // ===========================
  // Listen Incoming Call
  // ===========================

  Stream listenIncomingCall(
    String userId,
  ) {
    return _firestore
        .collection("calls")
        .where(
          "receiverId",
          isEqualTo: userId,
        )
        .where(
          "status",
          whereIn: [
            "calling",
            "ringing",
          ],
        )
        .snapshots();
  }

  // ===========================
  // Listen Call
  // ===========================

  Stream<DocumentSnapshot> listenCall(
    String callId,
  ) {
    return _firestore
        .collection("calls")
        .doc(callId)
        .snapshots();
  }

  // ===========================
  // Accept Call
  // ===========================

  Future<void> acceptCall({
    required String callId,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "status": "accepted",
      "acceptedAt":
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================
  // Reject Call
  // ===========================

  Future<void> rejectCall({
    required String callId,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "status": "rejected",
    });
  }

  // ===========================
  // End Call
  // ===========================

  Future<void> endCall({
    required String callId,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "status": "ended",
      "endedAt":
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================
  // Clear Call Data
  // ===========================

  Future clearCallData({
    required String callId,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "offer":
          FieldValue.delete(),
      "answer":
          FieldValue.delete(),
      "status":
          "ended",
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    print("🧹 Call Data Cleared");
  }

  // ===========================
  // Ringing Call
  // ===========================

  Future<void> setCallRinging({
    required String callId,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "status": "ringing",
    });
  }

  // ===========================
  // Save Offer
  // ===========================

  Future<void> saveOffer({
    required String callId,
    required RTCSessionDescription offer,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "offer": {
        "sdp": offer.sdp,
        "type": offer.type,
      },
    });
  }

  // ===========================
  // Save Answer
  // ===========================

  Future<void> saveAnswer({
    required String callId,
    required RTCSessionDescription answer,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .update({
      "answer": {
        "sdp": answer.sdp,
        "type": answer.type,
      },
    });
  }

  // ===========================
  // Get Call Stream
  // ===========================

  Stream<DocumentSnapshot> getCallStream(
    String callId,
  ) {
    return _firestore
        .collection("calls")
        .doc(callId)
        .snapshots();
  }

  // ===========================
  // Save ICE Candidate
  // ===========================

  Future<void> saveIceCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    required bool isCaller,
  }) async {
    await _firestore
        .collection("calls")
        .doc(callId)
        .collection(
          isCaller
              ? "callerCandidates"
              : "receiverCandidates",
        )
        .add({
      "candidate":
          candidate.candidate,
      "sdpMid":
          candidate.sdpMid,
      "sdpMLineIndex":
          candidate.sdpMLineIndex,
    });
  }

  // ===========================
  // Listen ICE Candidates
  // ===========================

  Stream<QuerySnapshot> listenIceCandidates({
    required String callId,
    required bool isCaller,
  }) {
    return _firestore
        .collection("calls")
        .doc(callId)
        .collection(
          isCaller
              ? "receiverCandidates"
              : "callerCandidates",
        )
        .snapshots();
  }
}