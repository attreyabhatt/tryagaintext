import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/suggestion.dart';

class ApiClient {
  final String
  baseUrl; // e.g. https://tryagaintext.com or http://10.0.2.2:8000 (Android emulator)

  ApiClient(this.baseUrl);

  /// Calls POST /api/generate/ and returns a list of suggestions.
  /// NOTE: Your Django returns reply as a JSON STRING of an array,
  /// so we decode twice.
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
    final replyString = map['reply'] as String? ?? '[]'; // JSON string
    final list = jsonDecode(replyString) as List<dynamic>; // now a List
    return list
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Calls POST /api/extract-image/ with a screenshot image file.
  /// Returns the extracted transcript as plain text.
  Future<String> extractFromImage(File image) async {
    final uri = Uri.parse('$baseUrl/api/extract-image/');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('screenshot', image.path));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw HttpException('Server ${streamed.statusCode}: $body');
    }

    final map = jsonDecode(body) as Map<String, dynamic>;
    return (map['conversation'] as String?) ?? '';
  }
}
