import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for handling image uploads to ImgBB.
class ImgbbService {
  static const String _apiKey = '061c6c639a90fb30bb348a1565be0eb4';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an image file to ImgBB and returns the direct display URL.
  static Future<String> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_apiKey'));
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['url'];
        } else {
          throw Exception('ImgBB API error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengunggah foto: $e');
    }
  }
}
