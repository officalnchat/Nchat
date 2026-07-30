import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String imageUrl;
  final String type;
  final String time;
  final bool isMe;
  final int status;

  // Swipe Reply Callback
  final VoidCallback? onSwipeReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.imageUrl,
    required this.type,
    required this.time,
    required this.isMe,
    this.status = 1,
    this.onSwipeReply,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onSwipeReply?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.transparent,
        child: const Icon(
          Icons.reply,
          color: Colors.green,
          size: 28,
        ),
      ),
      child: Align(
        alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 280,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.green.shade400
                : Colors.grey.shade300,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  Radius.circular(isMe ? 16 : 0),
              bottomRight:
                  Radius.circular(isMe ? 0 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [

              if (type == "image")
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                ),

              if (type == "text")
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),

              const SizedBox(height: 5),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),

                  if (isMe) ...[
                    const SizedBox(width: 4),

                    Icon(
                      status == 3
                          ? Icons.done_all
                          : status == 2
                              ? Icons.done_all
                              : Icons.done,
                      size: 16,
                      color: status == 3
                          ? Colors.blue
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}