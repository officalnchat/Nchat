import 'dart:io';

import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final String receiverId;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.receiverId,
  });

  @override
  State<ImagePreviewScreen> createState() =>
      _ImagePreviewScreenState();
}

class _ImagePreviewScreenState
    extends State<ImagePreviewScreen> {

  final TextEditingController
      captionController =
          TextEditingController();

  final StorageService
      _storageService =
          StorageService();

  final FirestoreService
      _firestoreService =
          FirestoreService();

  bool isSending = false;

  String? currentUserId;
   Future<void> sendImage() async {
  setState(() {
    isSending = true;
  });

  try {
    currentUserId =
        await _firestoreService.getCurrentUserId();

    final ids = [
      currentUserId!,
      widget.receiverId,
    ]..sort();

    final chatId = ids.join("_");

    String? imageUrl;

    try {
      imageUrl = await _storageService.uploadChatImage(
        imageFile: widget.imageFile,
        chatId: chatId,
      );
    } catch (e) {
      imageUrl = null;
    }

    if (imageUrl != null) {
      await _firestoreService.sendImageMessage(
        chatId: chatId,
        senderId: currentUserId!,
        receiverId: widget.receiverId,
        imageUrl: imageUrl,
        caption: captionController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Image storage is not available currently",
          ),
        ),
      );
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }

  if (mounted) {
    setState(() {
      isSending = false;
    });
  }
}
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Preview",
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: Center(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: captionController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: "Add a caption...",
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          onPressed: sendImage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }
}