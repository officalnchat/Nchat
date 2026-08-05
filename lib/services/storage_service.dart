import 'dart:io';

import 'cloudinary_service.dart';

class StorageService {
 final CloudinaryService _cloudinaryService =
    CloudinaryService();

  // Pick image from gallery
 Future<File?> pickImage() async {
  return await _cloudinaryService.pickImage();
}

  // Upload image to Firebase Storage
  Future<String?> uploadChatImage({
  required File imageFile,
  required String chatId,
}) async {
  try {
    return await _cloudinaryService.uploadImage(
      imageFile,
    );
  } catch (e) {
    print("IMAGE UPLOAD ERROR: $e");
    return null;
  }
}
}