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
  String? forwarded,
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

      'isStarred': false,
      
      'replyMessage': replyMessage ?? '',
'replyType': replyType ?? '',

       'forwarded': forwarded ?? '',

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

      // No text for image messages
      'message': caption ?? '',

      // Image URL
      'imageUrl': imageUrl,

      'timestamp':
          FieldValue.serverTimestamp(),

      // 1 = Sent
      // 2 = Delivered
      // 3 = Seen
      'status': 1,

      'type': 'image',

      'isStarred': false,

      'replyMessage': replyMessage ?? '',
'replyType': replyType ?? '',

      'forwarded': forwarded ?? '',

    });
  }
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

    "timestamp": FieldValue.serverTimestamp(),

    "status": 1,

    "isStarred": false,

    "forwarded": forwarded ?? "",

    "reaction": "",

    "replyMessage": replyMessage ?? "",

    "replyType": replyType ?? "",
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
    "deletedFor": FieldValue.arrayUnion([
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

Stream<QuerySnapshot> listenIncomingCall(
  String userId,
) {
  return FirebaseFirestore.instance
      .collection("calls")
      .where(
        "receiverId",
        isEqualTo: userId,
      )
      .where(
        "status",
        isEqualTo: "calling",
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
}