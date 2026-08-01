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
                CircleAvatar(
  radius: 20,
  backgroundImage: (snapshot.hasData &&
          snapshot.data!.exists &&
          ((snapshot.data!.data()
                      as Map<String, dynamic>)["photoUrl"] ??
                  "")
              .toString()
              .isNotEmpty)
      ? NetworkImage(
          (snapshot.data!.data()
                  as Map<String, dynamic>)["photoUrl"],
        )
      : null,
  child: (snapshot.hasData &&
          snapshot.data!.exists &&
          ((snapshot.data!.data()
                      as Map<String, dynamic>)["photoUrl"] ??
                  "")
              .toString()
              .isNotEmpty)
      ? null
      : const Icon(Icons.person),
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

  isStarred: message["isStarred"],

  forwarded: message["forwarded"],

  reaction: message["reaction"],


  replyMessage: message["replyMessage"],
replyType: message["replyType"],

  onSwipeReply: () {
  setState(() {
    chatController.setReplyMessage(message);
  });
},

onLongPress: () async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
  padding: const EdgeInsets.symmetric(
    vertical: 10,
  ),
  child: Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceEvenly,
    children: [
      _reactionButton(
        context,
        "❤️",
      ),
      _reactionButton(
        context,
        "😂",
      ),
      _reactionButton(
        context,
        "😮",
      ),
      _reactionButton(
        context,
        "😢",
      ),
      _reactionButton(
        context,
        "👍",
      ),
    ],
  ),
),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text("Reply"),
              onTap: () {
                Navigator.pop(context, "reply");
              },
            ),
            ListTile(
  leading: const Icon(
    Icons.forward,
    color: Colors.blue,
  ),
  title: const Text("Forward"),
  onTap: () {
    Navigator.pop(
      context,
      "forward",
    );
  },
),
            ListTile(
  leading: Icon(
    message["isStarred"]
        ? Icons.star
        : Icons.star_border,
    color: Colors.amber,
  ),
  title: Text(
    message["isStarred"]
        ? "Unstar Message"
        : "Star Message",
  ),
  onTap: () {
    Navigator.pop(
      context,
      "star",
    );
  },
),

             ListTile(
  leading: const Icon(
    Icons.delete_outline,
    color: Colors.orange,
  ),
  title: const Text("Delete for Me"),
  onTap: () {
    Navigator.pop(
      context,
      "deleteForMe",
    );
  },
),

            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text("Delete for Everyone"),
              onTap: () {
                Navigator.pop(context, "delete");
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Cancel"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
  if (action == "❤️" ||
    action == "😂" ||
    action == "😮" ||
    action == "😢" ||
    action == "👍") {
  await chatController.setReaction(
    message["docId"],
    action!,
  );
  return;
}

  if (action == "reply") {
    setState(() {
      chatController.setReplyMessage(message);
    });
  }

if (action == "forward") {
  setState(() {
    chatController.setForwardMessage(
      message,
    );
  });
}


if (action == "star") {
  await chatController.toggleStarMessage(
    message["docId"],
    message["isStarred"],
  );
}

 if (action == "deleteForMe") {
  await chatController.deleteMessageForMe(
    message["docId"],
  );
}

if (action == "delete") {
  await chatController.deleteMessage(
    message["docId"],
  );
}

},
);
                  },
                );
              },
            ),
          ),

if (chatController.forwardMessage != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      border: const Border(
        left: BorderSide(
          color: Colors.blue,
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
                "Forward Message",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                chatController.forwardMessage!["type"] == "image"
                    ? "📷 Photo"
                    : chatController.forwardMessage!["text"],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              chatController.clearForwardMessage();
            });
          },
          icon: const Icon(Icons.close),
        ),
      ],
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
   Widget _reactionButton(
    BuildContext context,
    String emoji,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(
          context,
          emoji,
        );
      },
      borderRadius:
          BorderRadius.circular(20),
      child: Padding(
        padding:
            const EdgeInsets.all(8),
        child: Text(
          emoji,
          style:
              const TextStyle(
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}