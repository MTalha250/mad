import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: CloudinaryConfig.maxWidth.toDouble(),
        imageQuality: CloudinaryConfig.quality,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<List<XFile>> pickMultipleImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: CloudinaryConfig.maxWidth.toDouble(),
        imageQuality: CloudinaryConfig.quality,
      );
      if (images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      return images;
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadToCloudinary(XFile image) async {
    try {
      final file = File(image.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: image.name,
        ),
        'upload_preset': CloudinaryConfig.uploadPreset,
      });

      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadMultipleToCloudinary(List<XFile> images) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadToCloudinary(image);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String?> pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    final image = await pickImage(source: source);
    if (image != null) {
      return await uploadToCloudinary(image);
    }
    return null;
  }

  Future<List<String>> pickAndUploadMultipleImages({int maxImages = 10}) async {
    final images = await pickMultipleImages(maxImages: maxImages);
    if (images.isNotEmpty) {
      return await uploadMultipleToCloudinary(images);
    }
    return [];
  }
}
