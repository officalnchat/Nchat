import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../controllers/chat_controller.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String photoUrl;
  final String receiverId;
  final bool isIncoming;
  final String? callId;

  final ChatController? existingController;

  const CallScreen({
  super.key,
  required this.userName,
  required this.photoUrl,
  required this.receiverId,
  this.isIncoming = false,
  this.callId,
  this.existingController,
});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  String? activeCallId;

  late ChatController chatController;


  // ===========================
// WebRTC Renderers
// ===========================

final RTCVideoRenderer localRenderer =
    RTCVideoRenderer();

final RTCVideoRenderer remoteRenderer =
    RTCVideoRenderer();


 bool isMuted = false;
bool isSpeakerOn = false;
bool isCallConnected = false;

Timer? _timer;

StreamSubscription<DocumentSnapshot>? _callListener;

bool _screenClosed = false;

int _seconds = 0;

String callStatus = "calling";

String callTime = "00:00";

void startTimer() {
  _timer?.cancel();

  _seconds = 0;

  _timer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      if (!mounted) return;

      setState(() {
        _seconds++;

        final minutes =
            (_seconds ~/ 60)
                .toString()
                .padLeft(2, "0");

        final seconds =
            (_seconds % 60)
                .toString()
                .padLeft(2, "0");

        callTime = "$minutes:$seconds";
      });
    },
  );
}

@override
void initState() {
  super.initState();

 chatController =
    widget.existingController ??
    ChatController(
      receiverId: widget.receiverId,
    );

  activeCallId = widget.callId;

  initializeCall();

  listenCallStatus();
}
Future initializeCall() async {

await localRenderer.initialize();

await remoteRenderer.initialize();


// Caller ke liye turant WebRTC start hoga
// Receiver ke liye accept ke time start hoga

if (!widget.isIncoming) {
  localRenderer.srcObject = chatController.localStream;
}


chatController.onRemoteStreamUpdate = () async {

  if (!mounted) return;

  final stream = chatController.getRemoteStream();

  if (stream == null) {
    return;
  }

  setState(() {
    remoteRenderer.srcObject = stream;
    isCallConnected = true;
  });

  if (_timer == null) {
    startTimer();
  }

  await Helper.setSpeakerphoneOn(isSpeakerOn);

  print("🎧 Remote Stream Attached");
  print("⏱️ Call Timer Started");
};
     if (!widget.isIncoming) {
  chatController.isCaller = true;
} else {
  chatController.isCaller = false;
}

  setState(() {});
}

// ===========================
// Listen Call Status
// ===========================

void listenCallStatus() async {
  final callId =
      activeCallId ??
      await chatController.getCallId();

  activeCallId = callId;

  print("📞 Listening CallId : $callId");

  _callListener =
      chatController.listenCall(callId).listen((snapshot) {

    if (!snapshot.exists) return;

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final status =
        data["status"] ?? "calling";

    if (!mounted) return;

    setState(() {
      callStatus = status;
    });

    print("📞 Call Status : $status");

    if (status == "accepted") {

  if (!mounted) return;

  setState(() {
    callStatus = "accepted";
  });
}

    if (status == "ended" ||
        status == "rejected") {

      _timer?.cancel();
      _timer = null;

      if (!_screenClosed &&
          mounted &&
          Navigator.canPop(context)) {

        _screenClosed = true;

        Navigator.pop(context);
      }
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 40),

            Text(
  widget.isIncoming
?
(
callStatus == "accepted"
?
"Voice Call"
:
"Incoming Voice Call"
)
:
(
callStatus == "accepted"
?
"Voice Call"
:
callStatus == "ringing"
?
"Ringing..."
:
"Calling..."
),
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 18,
  ),
),

            const SizedBox(height: 30),

            CircleAvatar(
              radius: 65,
              backgroundImage:
                  widget.photoUrl.isNotEmpty
                      ? NetworkImage(widget.photoUrl)
                      : null,
              child: widget.photoUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 70,
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
  callStatus == "accepted"
      ? callTime
      : "",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),

            const Spacer(),
                        if (widget.isIncoming && !isCallConnected)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 40,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                   FloatingActionButton(
  heroTag: "callerIncomingEnd",
  backgroundColor: Colors.red,
  onPressed: () async {

    _timer?.cancel();
    _timer = null;

    final callId =
        activeCallId ??
        await chatController.getCallId();

    activeCallId = callId;

    print("📴 Caller Ending Call: $callId");

    await chatController.endCall(callId);

    if (!mounted) return;

    if (!_screenClosed) {
      _screenClosed = true;
      Navigator.pop(context);
    }
  },
  child: const Icon(
    Icons.call_end,
    color: Colors.white,
  ),
),

                    FloatingActionButton(
  heroTag: "accept",
  backgroundColor: Colors.green,
 onPressed: () async {


if (activeCallId == null) {
  print("❌ CallId is null");
  return;
}

await chatController.acceptCall(activeCallId!);

localRenderer.srcObject = chatController.localStream;


if (!mounted) return;

setState(() {
  callStatus = "accepted";
});

},
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else if (!widget.isIncoming || isCallConnected)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 40,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
  heroTag: "mute",
  backgroundColor: isMuted
      ? Colors.orange
      : Colors.white,
  onPressed: () async {
  final tracks =
      chatController.localStream?.getAudioTracks();

  if (tracks == null || tracks.isEmpty) {
    print("❌ Mute: Local audio track not found");
    return;
  }

  final newMuteState = !isMuted;

  for (final track in tracks) {
    track.enabled = !newMuteState;
  }

  if (!mounted) return;

  setState(() {
    isMuted = newMuteState;
  });

  print(
    isMuted
        ? "🔇 Microphone Muted"
        : "🎤 Microphone Unmuted",
  );
},
  child: Icon(
    isMuted
        ? Icons.mic_off
        : Icons.mic,
    color: Colors.black,
  ),
),
                   FloatingActionButton(
  heroTag: "callerEnd",
  backgroundColor: Colors.red,
  onPressed: () async {
    print("📴 Caller End Button Pressed");

    _timer?.cancel();
    _timer = null;

    final callId =
        activeCallId ??
        chatController.currentCallId;

    if (callId == null || callId.isEmpty) {
      print("❌ Caller End: CallId is null");
      return;
    }

    activeCallId = callId;

    print("📴 Caller Ending CallId: $callId");

    await chatController.endCall(callId);

    if (!mounted) return;

    if (!_screenClosed) {
      _screenClosed = true;
      Navigator.pop(context);
    }
  },
  child: const Icon(
    Icons.call_end,
    color: Colors.white,
  ),
),

                    FloatingActionButton(
                      heroTag: "speaker",
                      backgroundColor: isSpeakerOn
                          ? Colors.orange
                          : Colors.white,
                      onPressed: () async {

setState(() {
  isSpeakerOn = !isSpeakerOn;
});

await Helper.setSpeakerphoneOn(
  isSpeakerOn,
);

print(
"🔊 Speaker : $isSpeakerOn",
);

},
                      child: Icon(
                        isSpeakerOn
                            ? Icons.volume_up
                            : Icons.hearing,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
@override
void dispose() {
  _timer?.cancel();

  _callListener?.cancel();

  chatController.onRemoteStreamUpdate = null;

  // Sirf temporary controller ko dispose karo.
  // Existing controller ChatScreen ka hai,
  // isliye usko yahan destroy nahi karna hai.
  if (widget.existingController == null) {
    chatController.dispose();
  }

  localRenderer.dispose();
  remoteRenderer.dispose();

  super.dispose();
}
}