import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = "f197bx1w";
  static const String uploadPreset = "nchat_upload";

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  Future<String?> uploadImage(
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request =
          http.MultipartRequest(
        "POST",
        uri,
      );

      request.fields["upload_preset"] =
          uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          imageFile.path,
        ),
      );
            final response =
          await request.send();

      final responseData =
          await response.stream.bytesToString();

      final data =
          jsonDecode(responseData);

      if (response.statusCode == 200) {
        return data["secure_url"];
      } else {
        print(
          "❌ Cloudinary Upload Error : $responseData",
        );
        return null;
      }
    } catch (e) {
      print(
        "❌ Cloudinary Exception : $e",
      );
      return null;
    }
  }
}