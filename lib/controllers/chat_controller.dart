import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/webrtc_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ChatController extends ChangeNotifier {
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

  final WebRTCService _webRTCService =
    WebRTCService();    

      // ===========================
// Voice Recording
// ===========================

final AudioRecorder audioRecorder = AudioRecorder();

bool isRecording = false;

String? audioPath;

// Start Recording
Future<void> startRecording() async {
  if (await audioRecorder.hasPermission()) {
    final dir = await getTemporaryDirectory();

    final path =
        "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

    await audioRecorder.start(
      const RecordConfig(),
      path: path,
    );

    isRecording = true;

    print("🎤 Recording Started");
  } else {
    print("❌ Microphone Permission Denied");
  }
}

// Stop Recording
Future<String?> stopRecording() async {
  audioPath = await audioRecorder.stop();

  isRecording = false;

  return audioPath;
}

  List<Map<String, dynamic>> messages = [];

// ===========================
// Search
// ===========================

final TextEditingController searchController =
    TextEditingController();

List<Map<String, dynamic>> filteredMessages = [];

bool isSearching = false;

String searchQuery = "";

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

  String? currentCallId;

  bool? isCaller;
  // ===========================
// Voice Call Listeners
// ===========================

StreamSubscription<DocumentSnapshot>? _callSubscription;

StreamSubscription<QuerySnapshot>? _iceSubscription;

bool _disposed = false;

  RTCPeerConnection? peerConnection;

  MediaStream? localStream;

  MediaStream? remoteStream;

  VoidCallback? onRemoteStreamUpdate;

  bool offerReceived = false;

  bool answerReceived = false;

  bool _webRtcInitialized = false;

  MediaStream? getRemoteStream() {
  return remoteStream;
}

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
// Get Call Id
// ===========================

Future<String> getCallId() async {

currentUserId ??=
await _firestoreService.getCurrentUserId();

if (currentCallId != null) {
  return currentCallId!;
}

currentCallId =
_firestoreService.getCallId(
  user1: currentUserId!,
  user2: receiverId,
);

return currentCallId!;
}
// ===========================
// Initialize WebRTC
// ===========================

Future<void> initializeWebRTC() async {

  if (_webRtcInitialized) {
  print("✅ WebRTC Already Initialized");
  return;
}

_webRtcInitialized = true;

  await _webRTCService.initialize();

  peerConnection =
      _webRTCService.peerConnection;

  localStream =
      _webRTCService.localStream;

  remoteStream =
      _webRTCService.remoteStream;

  print("🎤 WebRTC Initialized");
  peerConnection!.onIceCandidate =
    (RTCIceCandidate candidate) async {

  final callId = await getCallId();

  await _firestoreService.saveIceCandidate(
  callId: callId,
  candidate: candidate,
  isCaller: isCaller ?? false,
);

  print("🧊 ICE Candidate Sent");
};
peerConnection!.onTrack =
    (RTCTrackEvent event) {

  if (event.streams.isNotEmpty) {

    remoteStream =
        event.streams.first;


    print(
      "🎤 Remote Audio Connected",
    );


    onRemoteStreamUpdate?.call();

  }

};
peerConnection!.onConnectionState = (state) {
  print("🌐 Connection State : $state");
};

peerConnection!.onIceConnectionState = (state) {
  print("🧊 ICE Connection State : $state");
};

peerConnection!.onSignalingState = (state) {
  print("📡 Signaling State : $state");
};
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
}

// ===========================
// Mark Messages Seen
// ===========================

Future<void> markMessagesSeen() async {

  final chatId = await getChatId();

  currentUserId ??=
      await _firestoreService.getCurrentUserId();

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

        "audioUrl": data["audioUrl"] ?? "",
        
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
    
   if (searchQuery.trim().isEmpty) {
  filteredMessages = List.from(messages);
} else {
  searchMessages(searchQuery);
}
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

  searchQuery = query;

  if (query.trim().isEmpty) {
    filteredMessages = List.from(messages);
    return;
  }

  final lowerQuery =
      query.toLowerCase().trim();

  filteredMessages = messages.where((message) {

    final text =
        message["text"]
            .toString()
            .toLowerCase();

    return text.contains(lowerQuery);

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
// Send Voice
// ===========================

Future<void> sendVoiceMessage(
  BuildContext context,
  VoidCallback refresh,
) async {
  if (audioPath == null) return;

  currentUserId ??=
      await _firestoreService.getCurrentUserId();

  final chatId = await getChatId();

  final ref = FirebaseStorage.instance
      .ref()
      .child("chat_audio")
      .child(
        "${DateTime.now().millisecondsSinceEpoch}.m4a",
      );

  await ref.putFile(File(audioPath!));

  final audioUrl =
      await ref.getDownloadURL();

  await _firestoreService.sendVoiceMessage(
    chatId: chatId,
    senderId: currentUserId!,
    receiverId: receiverId,
    audioUrl: audioUrl,

    replyMessage:
        replyMessage?["text"],

    replyType:
        replyMessage?["type"],

    forwarded: "",
  );

  await setTyping(false);

  clearReplyMessage();

  clearForwardMessage();

  audioPath = null;

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
// Start Voice Call
// ===========================

// ===========================
// Start Voice Call
// ===========================

Future<void> startVoiceCall() async {

  isCaller = true;

  currentUserId ??=
      await _firestoreService.getCurrentUserId();

  currentCallId =
      await _firestoreService.startVoiceCall(
        callerId: currentUserId!,
        receiverId: receiverId,
      );
      print(
"📞 Current Call ID : $currentCallId"
);

  await initializeWebRTC();

  listenSignaling();

  listenIceCandidates(true);

  await createOffer();

  print("📞 Voice Call Started");
  print("📞 CallId : $currentCallId");
}



// ===========================
// Dispose
// ===========================

@override
void dispose() {

  _disposed = true;

_callSubscription?.cancel();

_iceSubscription?.cancel();

  setTyping(false);

  audioRecorder.dispose();

  messageController.dispose();

  scrollController.dispose();

  searchController.dispose();

  _webRTCService.dispose();

  currentCallId = null;
  peerConnection = null;
  localStream = null;
  remoteStream = null;

  offerReceived = false;
  answerReceived = false;

_addedCandidates.clear();
_pendingIceCandidates.clear();
_remoteDescriptionSet = false;

_webRtcInitialized = false;

  super.dispose();
}

// ===========================
// Listen Call
// ===========================

Stream<DocumentSnapshot> listenCall(
  String callId,
) {
  return _firestoreService.listenCall(
    callId,
  );
}
// ===========================
// Set Call Ringing
// ===========================

Future<void> setCallRinging() async {

  final callId =
      await getCallId();

  await _firestoreService.setCallRinging(
    callId: callId,
  );

  print("📞 Call Status Updated: Ringing");
}

// ===========================
// Accept Call
// ===========================

Future acceptCall(String callId) async {

isCaller = false;

currentCallId = callId;


await _firestoreService.acceptCall(
callId: callId,
);


print("✅ Call Accepted");


await initializeWebRTC();


listenSignaling();


listenIceCandidates(false);


await createAnswer();


print("🎧 Receiver WebRTC Ready");

}

// ===========================
// Reject Call
// ===========================

// ===========================
// Reject Call
// ===========================

Future rejectCall(String callId) async {

  currentCallId = callId;

  await _firestoreService.rejectCall(
    callId: callId,
  );

  await _webRTCService.dispose();

  peerConnection = null;
  localStream = null;
  remoteStream = null;

  offerReceived = false;
answerReceived = false;

_addedCandidates.clear();
_pendingIceCandidates.clear();
_remoteDescriptionSet = false;

currentCallId = null;

  _webRtcInitialized = false;

  print("❌ Call Rejected");
}
// ===========================
// Create Offer
// ===========================

Future<void> createOffer() async {

  if (peerConnection == null) {
    await initializeWebRTC();
  }

  final callId =
      await getCallId();

  final offer =
      await _webRTCService.createOffer();

  await _firestoreService.saveOffer(
    callId: callId,
    offer: offer,
  );

  print("📤 Offer Saved");
}

// ===========================
// Create Answer
// ===========================

Future<void> createAnswer() async {

  if (!offerReceived) {

  print(
    "⏳ Waiting for Offer...",
  );

  return;

}

  if (peerConnection == null) {
    await initializeWebRTC();
  }

  final callId =
      await getCallId();

  final answer =
      await _webRTCService.createAnswer();

  await _firestoreService.saveAnswer(
    callId: callId,
    answer: answer,
  );

  print("📥 Answer Saved");
}
// ===========================
// Listen Signaling
// ===========================

void listenSignaling() async {
  final callId = await getCallId();

  _callSubscription?.cancel();

_callSubscription =
    _firestoreService
        .getCallStream(callId)
        .listen((snapshot) async {

    if (!snapshot.exists) return;

    if (_disposed) return;

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    // Offer
  if (isCaller == false &&
    data["offer"] != null &&
    !offerReceived) {

  final offer = RTCSessionDescription(
    data["offer"]["sdp"],
    data["offer"]["type"],
  );

  await _webRTCService.setRemoteDescription(
  offer,
);

_remoteDescriptionSet = true;

offerReceived = true;

for (final candidate in _pendingIceCandidates) {
  await _webRTCService.addIceCandidate(candidate);
}

_pendingIceCandidates.clear();

print("🧊 Pending ICE Candidates Added");

print("📥 Offer Received");

  // Offer milne ke baad hi Answer create karo
  await createAnswer();

  print("📤 Answer Created");
}

    // Answer
    if (isCaller == true &&
    data["answer"] != null &&
    !answerReceived) {
  final answer = RTCSessionDescription(
    data["answer"]["sdp"],
    data["answer"]["type"],
  );

  await _webRTCService.setRemoteDescription(
  answer,
);

_remoteDescriptionSet = true;

answerReceived = true;

for (final candidate in _pendingIceCandidates) {
  await _webRTCService.addIceCandidate(candidate);
}

_pendingIceCandidates.clear();

print("🧊 Pending ICE Candidates Added");

notifyListeners();

print("📥 Answer Received & Remote Description Set");
}  
  });
}
// ===========================
// Listen ICE Candidates
// ===========================

final Set<String> _addedCandidates = {};

final List<RTCIceCandidate> _pendingIceCandidates = [];

bool _remoteDescriptionSet = false;

void listenIceCandidates(
  bool isCaller,
) async {
  final callId = await getCallId();

  _iceSubscription?.cancel();

  _iceSubscription =
      _firestoreService
          .listenIceCandidates(
            callId: callId,
            isCaller: isCaller,
          )
          .listen((snapshot) async {
    for (final doc in snapshot.docs) {
      if (_addedCandidates.contains(doc.id)) {
        continue;
      }

      _addedCandidates.add(doc.id);

      final data =
          doc.data() as Map<String, dynamic>;

      final candidate = RTCIceCandidate(
        data["candidate"],
        data["sdpMid"],
        data["sdpMLineIndex"],
      );

      if (_remoteDescriptionSet) {
        await _webRTCService.addIceCandidate(
          candidate,
        );

        print("🧊 ICE Added : ${doc.id}");
      } else {
        _pendingIceCandidates.add(candidate);

        print(
          "⏳ ICE Queued : ${doc.id}",
        );
      }
    }
  });
}

// ===========================
// End Call
// ===========================

// ===========================
// End Call
// ===========================

Future endCall(String callId) async {

  currentCallId = callId;

  await _firestoreService.endCall(
    callId: callId,
  );

  await _webRTCService.dispose();

  peerConnection = null;
  localStream = null;
  remoteStream = null;

  _webRtcInitialized = false;
  offerReceived = false;
answerReceived = false;

_addedCandidates.clear();
_pendingIceCandidates.clear();
_remoteDescriptionSet = false;

currentCallId = null;

  print("📴 Call Ended");
}
}