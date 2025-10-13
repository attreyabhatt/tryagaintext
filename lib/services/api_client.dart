import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/suggestion.dart';
import '../models/generate_response.dart';
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl);

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  Future<List<Suggestion>> generate({
    required String lastText,
    required String situation,
    String herInfo = '',
  }) async {
    try {
      final headers = await _getHeaders();

      print('Generating with headers: $headers'); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate/'),
        headers: headers,
        body: jsonEncode({
          'last_text': lastText,
          'situation': situation,
          'her_info': herInfo,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);
      final generateResponse = GenerateResponse.fromJson(data);

      if (!generateResponse.success) {
        if (generateResponse.error == 'insufficient_credits') {
          throw InsufficientCreditsException(
            generateResponse.message ?? 'No credits remaining',
          );
        } else if (generateResponse.error == 'trial_expired') {
          throw TrialExpiredException(
            generateResponse.message ?? 'Trial expired',
          );
        } else {
          throw ApiException(generateResponse.message ?? 'Generation failed');
        }
      }

      // Update stored credits if available
      if (generateResponse.creditsRemaining != null) {
        await AuthService.updateStoredCredits(
          generateResponse.creditsRemaining!,
        );
      }

      // Parse reply into suggestions
      return _parseReplyToSuggestions(generateResponse.reply ?? '');
    } catch (e) {
      print('Generate error: $e'); // Debug log
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error. Please try again.');
    }
  }

  Future<String> extractFromImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/extract-image/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('screenshot', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['error'] == 'insufficient_credits') {
        throw InsufficientCreditsException(
          data['conversation'] ?? 'No credits remaining',
        );
      }

      if (data['trial_expired'] == true) {
        throw TrialExpiredException(data['conversation'] ?? 'Trial expired');
      }

      // Update stored credits if available
      if (data['credits_remaining'] != null) {
        await AuthService.updateStoredCredits(data['credits_remaining']);
      }

      return data['conversation'] ?? '';
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to extract conversation from image');
    }
  }

  List<Suggestion> _parseReplyToSuggestions(String reply) {
    final suggestions = <Suggestion>[];

    if (reply.trim().isEmpty) {
      return suggestions;
    }

    try {
      // Try to parse as JSON array
      final decoded = jsonDecode(reply.trim());

      if (decoded is List) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final message = item['message']?.toString();
            final confidenceScore = item['confidence_score'];

            if (message != null && message.trim().isNotEmpty) {
              double confidence = 0.8;
              if (confidenceScore is num) {
                confidence = confidenceScore.toDouble();
              }

              suggestions.add(
                Suggestion(message: message.trim(), confidence: confidence),
              );
            }
          }
        }
      }

      return suggestions;
    } catch (e) {
      // If JSON parsing fails, treat as plain text
      final lines = reply
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          // Remove numbering and cleanup
          String cleanLine = line
              .replaceFirst(RegExp(r'^\d+\.\s*'), '')
              .replaceFirst(RegExp(r'^-\s*'), '');

          if (cleanLine.isNotEmpty) {
            suggestions.add(
              Suggestion(
                message: cleanLine,
                confidence: _calculateConfidence(i, lines.length),
              ),
            );
          }
        }
      }
    }

    return suggestions;
  }

  double _calculateConfidence(int index, int total) {
    if (total == 1) return 0.85;

    switch (index) {
      case 0:
        return 0.9;
      case 1:
        return 0.8;
      case 2:
        return 0.7;
      default:
        return 0.6;
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class InsufficientCreditsException extends ApiException {
  InsufficientCreditsException(String message) : super(message);
}

class TrialExpiredException extends ApiException {
  TrialExpiredException(String message) : super(message);
}
