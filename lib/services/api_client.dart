import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/suggestion.dart';

class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl);

  /// Calls POST /api/generate/ and returns a list of suggestions.
  Future<List<Suggestion>> generate({
    required String lastText,
    required String situation,
    String herInfo = "",
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate/');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'last_text': lastText,
            'situation': situation,
            'her_info': herInfo,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw HttpException('Server ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final replyString = map['reply'] as String? ?? '[]';
    final list = jsonDecode(replyString) as List<dynamic>;
    return list
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Calls POST /api/extract-image/ with a screenshot image file.
  Future<String> extractFromImage(File image) async {
    final uri = Uri.parse('$baseUrl/api/extract-image/');

    try {
      // Read file bytes
      final bytes = await image.readAsBytes();
      print('📱 Mobile Debug - File path: ${image.path}');
      print('📱 Mobile Debug - File size: ${bytes.length} bytes');
      print('📱 Mobile Debug - Request URI: $uri');

      // Check if file is empty
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      // Create the multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add the file with explicit filename and try different approaches
      final multipartFile = http.MultipartFile.fromBytes(
        'screenshot', // This must match your Django field name
        bytes,
        filename: 'mobile_screenshot.jpg', // Explicit filename
      );

      request.files.add(multipartFile);

      print('📱 Mobile Debug - Multipart file added:');
      print('   - Field name: screenshot');
      print('   - Filename: mobile_screenshot.jpg');
      print('   - Size: ${bytes.length} bytes');

      // Send request
      print('📱 Mobile Debug - Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      print(
        '📱 Mobile Debug - Response status: ${streamedResponse.statusCode}',
      );

      // Get response body
      final responseBody = await streamedResponse.stream.bytesToString();
      print('📱 Mobile Debug - Response body: $responseBody');

      if (streamedResponse.statusCode != 200) {
        throw HttpException(
          'Server error ${streamedResponse.statusCode}: $responseBody',
        );
      }

      // Parse response
      final Map<String, dynamic> responseMap;
      try {
        responseMap = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        print('📱 Mobile Debug - JSON parse error: $e');
        throw Exception('Invalid response format');
      }

      final conversation = responseMap['conversation'] as String? ?? '';

      if (conversation.isEmpty) {
        throw Exception('No conversation extracted from image');
      }

      print(
        '📱 Mobile Debug - Success! Extracted ${conversation.length} characters',
      );
      return conversation;
    } catch (e) {
      print('📱 Mobile Debug - Error: $e');
      rethrow;
    }
  }
}
