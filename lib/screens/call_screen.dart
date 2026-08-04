import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../controllers/chat_controller.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String photoUrl;
  final String receiverId;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.userName,
    required this.photoUrl,
    required this.receiverId,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  late ChatController chatController;

 bool isMuted = false;
bool isSpeakerOn = false;
bool isCallConnected = false;

Timer? _timer;

StreamSubscription<DocumentSnapshot>? _callListener;

bool _screenClosed = false;

int _seconds = 0;

String callStatus = "ringing";

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

  chatController = ChatController(
    receiverId: widget.receiverId,
  );

  listenCallStatus();
}

// ===========================
// Listen Call Status
// ===========================

void listenCallStatus() async {

  final callId =
      await chatController.getCallId();

      print("📞 Listening CallId : $callId");

  _callListener =
      chatController
          .listenCall(callId)
          .listen((snapshot) {

    if (!snapshot.exists) return;

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final status =
        data["status"] ?? "";

        if (mounted) {
  setState(() {
    callStatus = status;
  });
}

    print("📞 Call Status : $status");

   if (status == "accepted") {

  if (!isCallConnected) {
    setState(() {
      isCallConnected = true;
    });
  }

  if (_timer == null) {
    startTimer();
  }
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
  callStatus == "calling"
      ? "Calling..."
      : callStatus == "ringing"
          ? "Ringing..."
          : callStatus == "accepted"
              ? "Voice Call"
              : "Call Ended",
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
                    heroTag: "end",
                     backgroundColor: Colors.red,
                     onPressed: () async {
  _timer?.cancel();

  await chatController.rejectCall();

  // Firestore listener screen automatically close karega.
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

  await chatController.acceptCall();

  if (!mounted) return;

  setState(() {
    callStatus = "accepted";
    isCallConnected = true;
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
                      onPressed: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                      },
                      child: Icon(
                        isMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: Colors.black,
                      ),
                    ),

                    FloatingActionButton(
                      heroTag: "end",
                      backgroundColor: Colors.red,
                     onPressed: () async {
  _timer?.cancel();

  await chatController.endCall();

  // Firestore listener screen automatically close karega.
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
                      onPressed: () {
                        setState(() {
                          isSpeakerOn =
                              !isSpeakerOn;
                        });
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

  super.dispose();

}
}