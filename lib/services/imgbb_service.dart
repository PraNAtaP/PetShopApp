import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service for handling image uploads to ImgBB.
class ImgbbService {
  static const String _apiKey = '6d207e02198a847aa98d0a2a901485a5';
  static const String _uploadUrl = 'https://freeimage.host/api/1/upload';

  /// Uploads an image file to ImgBB and returns the direct display URL.
  static Future<String> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
      request.files.add(
        await http.MultipartFile.fromPath('source', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status_code'] == 200 || responseData['success'] != null) {
          final imageUrl = responseData['image']?['url'] ?? responseData['data']?['url'];
          if (imageUrl != null) return imageUrl;
          throw Exception('URL not found in response: ${response.body}');
        } else {
          throw Exception('API error: ${response.body}');
        }
      } else {
        throw Exception('Failed to upload image. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengunggah foto: $e');
    }
  }

  /// Uploads image bytes to ImgBB (used for Web).
  static Future<String> uploadImageBytes(Uint8List imageBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
      request.fields['source'] = base64Encode(imageBytes);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status_code'] == 200 || responseData['success'] != null) {
          final imageUrl = responseData['image']?['url'] ?? responseData['data']?['url'];
          if (imageUrl != null) return imageUrl;
          throw Exception('URL not found in response: ${response.body}');
        } else {
          throw Exception('API error: ${response.body}');
        }
      } else {
        throw Exception('Failed to upload image. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengunggah foto: $e');
    }
  }
}
