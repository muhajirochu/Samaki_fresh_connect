import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// Handles image uploads to Cloudinary using the unsigned upload preset.
class CloudinaryService {
  static const String _cloudName = 'dsfx5mekf';
  static const String _uploadPreset = 'Samaki_Fresh_Unsigend';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final Dio _dio;

  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Uploads a single image file and returns the secure URL.
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      AppLogger.info('Uploading image to Cloudinary: ${imageFile.path}');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
        ),
        'upload_preset': _uploadPreset,
        if (folder != null) 'folder': folder,
      });

      final response = await _dio.post(
        _uploadUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String;
        AppLogger.info('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
            'Cloudinary upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('Cloudinary DioException: ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.error('Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Uploads multiple image files and returns a list of secure URLs.
  Future<List<String>> uploadImages(
    List<File> imageFiles, {
    String? folder,
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(imageFiles[i], folder: folder);
      urls.add(url);
      onProgress?.call(i + 1, imageFiles.length);
    }
    return urls;
  }
}
