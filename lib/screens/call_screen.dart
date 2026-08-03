import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../controllers/chat_controller.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String photoUrl;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.userName,
    required this.photoUrl,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  final ChatController chatController =
    ChatController(
      receiverId: "",
    );

 bool isMuted = false;
bool isSpeakerOn = false;

Timer? _timer;

int _seconds = 0;

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

  if (!widget.isIncoming) {
    startTimer();
  }
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
                  ? "Incoming Voice Call"
                  : "Calling...",
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
              callTime,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),

            const Spacer(),
                        if (widget.isIncoming)
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

  if (!mounted) return;

  Navigator.pop(context);
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

  startTimer();

  setState(() {});
},
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
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

  if (!mounted) return;

  Navigator.pop(context);
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
  super.dispose();
}
}