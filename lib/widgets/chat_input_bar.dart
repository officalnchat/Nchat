import 'dart:async';
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onTypingChanged;
  final VoidCallback onSend;
  final VoidCallback onImageTap;
  final VoidCallback onMicLongPress;
  final VoidCallback onMicLongPressEnd;

 const ChatInputBar({
  super.key,
  required this.controller,
  required this.onTypingChanged,
  required this.onSend,
  required this.onImageTap,
  required this.onMicLongPress,
   required this.onMicLongPressEnd,
});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool isTyping = false;

  bool isRecording = false;

  int recordingSeconds = 0;

  Timer? recordingTimer;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_typingListener);
  }

  void _typingListener() {
    final typing = widget.controller.text.trim().isNotEmpty;

    if (typing != isTyping) {
      isTyping = typing;

      widget.onTypingChanged(typing);

      setState(() {});
    }
  }
  void startRecordingTimer() {
  recordingSeconds = 0;

  recordingTimer?.cancel();

  recordingTimer = Timer.periodic(
    const Duration(seconds: 1),
    (_) {
      if (!mounted) return;

      setState(() {
        recordingSeconds++;
      });
    },
  );
}

void stopRecordingTimer() {
  recordingTimer?.cancel();

  if (!mounted) return;

  setState(() {
    recordingSeconds = 0;
  });
}

  @override
  void dispose() {
    recordingTimer?.cancel();
    widget.controller.removeListener(_typingListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.grey,
                      ),
                    ),

                    Expanded(
  child: isRecording
      ? Row(
          children: [
            const Icon(
              Icons.mic,
              color: Colors.red,
            ),

            const SizedBox(width: 8),

            const Text(
              "Recording...",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            Text(
              "${recordingSeconds}s",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
      : TextField(
          controller: widget.controller,
          minLines: 1,
          maxLines: 5,
          textCapitalization:
              TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: "Type a message",
            border: InputBorder.none,
          ),
        ),
),

                    IconButton(
  onPressed: widget.onImageTap,
  icon: const Icon(
    Icons.attach_file,
    color: Colors.grey,
  ),
),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            CircleAvatar(
  radius: 26,
  backgroundColor: isTyping
    ? Colors.green
    : isRecording
        ? Colors.red
        : Colors.blue,
  child: GestureDetector(
  onLongPress: () {
  if (!isTyping) {
    setState(() {
      isRecording = true;
    });

    startRecordingTimer();

    widget.onMicLongPress();
  }
},

 onLongPressEnd: (_) {
  if (!isTyping) {
    setState(() {
      isRecording = false;
    });

    stopRecordingTimer();

    widget.onMicLongPressEnd();
  }
},
    child: IconButton(
      onPressed: () {
        if (isTyping) {
          widget.onSend();
        }
      },
      icon: Icon(
        isTyping
            ? Icons.send
            : Icons.mic_none,
        color: Colors.white,
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}