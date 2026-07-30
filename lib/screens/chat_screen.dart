import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

import '../controllers/chat_controller.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController chatController;

  bool isSearchMode = false;

  @override
  void initState() {
    super.initState();

    chatController = ChatController(
      receiverId: widget.receiverId,
    );
  }

 @override
void dispose() {
  isSearchMode = false;

  chatController.dispose();

  super.dispose();
}

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: isSearchMode
    ? TextField(
        controller: chatController.searchController,
        autofocus: true,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          hintText: "Search messages...",
          hintStyle: TextStyle(
            color: Colors.white70,
          ),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            chatController.searchMessages(value);
          });
        },
      )
    : StreamBuilder<DocumentSnapshot>(
          stream: chatController.getReceiver(),
          builder: (context, snapshot) {
            String status = "Offline";
            bool typing = false;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data =
                  snapshot.data!.data() as Map<String, dynamic>;

              final bool isOnline =
                  data["isOnline"] ?? false;

              typing = data["isTyping"] ?? false;

              if (typing) {
                status = "Typing...";
              } else if (isOnline) {
                status = "Online";
              } else {
                status = chatController.formatLastSeen(
                  data["lastSeen"],
                );
              }
            }

            return Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: typing
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontWeight: typing
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
  if (!isSearchMode) ...[
    IconButton(
      onPressed: () {
        setState(() {
          isSearchMode = true;
        });
      },
      icon: const Icon(Icons.search),
    ),

    IconButton(
      onPressed: () {
        // Video Call
      },
      icon: const Icon(Icons.videocam),
    ),

    IconButton(
      onPressed: () {
        // Voice Call
      },
      icon: const Icon(Icons.call),
    ),

    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.more_vert),
    ),
  ] else ...[
    IconButton(
      onPressed: () {
        setState(() {
          isSearchMode = false;

          chatController.searchController.clear();

          chatController.searchMessages("");
        });
      },
      icon: const Icon(Icons.close),
    ),
  ],
],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatController.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Something went wrong",
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

               chatController.loadMessages(
  snapshot.data!,
);

chatController.updateMessageStatus();

if (chatController.searchController.text.isNotEmpty) {
  chatController.searchMessages(
    chatController.searchController.text,
  );
}
                return ListView.builder(
                  controller:
                      chatController.scrollController,
                  itemCount:
                      chatController.filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message =
                        chatController.filteredMessages[index];
                    return MessageBubble(
  message: message["text"],
  imageUrl: message["imageUrl"],
  type: message["type"],
  time: message["time"],
  isMe: message["isMe"],
  status: message["status"],

  replyMessage: message["replyMessage"],
replyType: message["replyType"],

  onSwipeReply: () {
    setState(() {
      chatController.setReplyMessage(message);
    });
  },
);
                  },
                );
              },
            ),
          ),

if (chatController.replyMessage != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      border: Border(
        left: BorderSide(
          color: Colors.green,
          width: 4,
        ),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Replying to",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
             Text(
  chatController.replyMessage!["type"] == "image"
      ? "📷 Photo"
      : chatController.replyMessage!["text"],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {
            setState(() {
              chatController.clearReplyMessage();
            });
          },
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  ),

          ChatInputBar(
  controller:
      chatController.messageController,

  onTypingChanged: (typing) async {
    await chatController.setTyping(
      typing,
    );
  },

  onSend: () {
    chatController.sendMessage(
      context,
      refresh,
    );
  },

  onImageTap: () {
    chatController.sendImage(
      context,
      refresh,
    );
  },
),
        ],
      ),
    );
  } 
}