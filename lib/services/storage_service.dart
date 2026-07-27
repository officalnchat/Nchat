import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  // Upload image to Firebase Storage
  Future<String?> uploadChatImage({
    required File imageFile,
    required String chatId,
  }) async {
    try {
      final String fileName =
          "${DateTime.now().millisecondsSinceEpoch}.jpg";

      final Reference ref = _storage
          .ref()
          .child("chat_images")
          .child(chatId)
          .child(fileName);

      final UploadTask uploadTask =
          ref.putFile(imageFile);

      final TaskSnapshot snapshot =
          await uploadTask;

      final String downloadUrl =
          await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Image Upload Error: $e");
      return null;
    }
  }
}