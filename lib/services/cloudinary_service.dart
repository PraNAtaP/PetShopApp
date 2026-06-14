import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

/// Service for handling image uploads to Cloudinary securely using Signed Uploads.
class CloudinaryService {
  static const String cloudName = 'dftfpu7tp';
  static const String apiKey = '214629568521827';
  static const String apiSecret = 'VPWlrJAjxxCoPlsKr6Vlb86zITU';
  
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Generates the SHA-1 signature required by Cloudinary for secure uploads.
  static String _generateSignature(Map<String, String> params) {
    // 1. Sort parameters alphabetically by key
    final sortedKeys = params.keys.toList()..sort();
    
    // 2. Create the string to sign: key1=value1&key2=value2...
    final List<String> paramsList = [];
    for (final key in sortedKeys) {
      paramsList.add('$key=${params[key]}');
    }
    final stringToSign = '${paramsList.join('&')}$apiSecret';
    
    // 3. Hash with SHA-1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Uploads an image file to Cloudinary and returns the secure URL.
  static Future<String> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      return uploadImageBytes(bytes, filename);
    } catch (e) {
      debugPrint('Error preparing file for Cloudinary: $e');
      throw Exception('Failed to process image file');
    }
  }

  /// Uploads image bytes to Cloudinary (used for Web and memory images).
  static Future<String> uploadImageBytes(Uint8List bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Timestamp is required for signed uploads
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // Parameters to sign
      final paramsToSign = {
        'timestamp': timestamp,
      };

      // Generate signature
      final signature = _generateSignature(paramsToSign);

      // Add text fields
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;

      // Add the file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'), // Cloudinary will auto-detect exact type
      );
      request.files.add(multipartFile);

      // Send request
      debugPrint('Uploading image to Cloudinary...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);
        debugPrint('Cloudinary upload successful!');
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: $responseData');
        throw Exception('Cloudinary error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception during Cloudinary upload: $e');
      throw Exception('Gagal upload gambar ke Cloudinary: $e');
    }
  }
}
