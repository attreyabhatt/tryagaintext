import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/generate_response.dart';
import '../models/suggestion.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;

  ApiClient([String? baseUrl]) : baseUrl = baseUrl ?? AppConfig.baseUrl;

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
    required String tone,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate/'),
        headers: headers,
        body: jsonEncode({
          'last_text': lastText,
          'situation': situation,
          'her_info': herInfo,
          'tone': tone,
        }),
      );

      final data = _decodeJson(response.body);
      final generateResponse = GenerateResponse.fromJson(data);

      if (!generateResponse.success) {
        throw ApiException(
          generateResponse.message ?? 'Generation failed',
          _mapErrorCode(generateResponse.error),
        );
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
      if (e is ApiException) {
        rethrow;
      }
      AppLogger.error('Generate error', e is Exception ? e : null);
      throw ApiException('Network error. Please try again.', ApiErrorCode.network);
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
        await http.MultipartFile.fromPath(
          'screenshot',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeJson(response.body);

      if (data['error'] == 'insufficient_credits') {
        throw ApiException(
          data['conversation'] ?? 'No credits remaining',
          ApiErrorCode.insufficientCredits,
        );
      }

      if (data['trial_expired'] == true) {
        throw ApiException(
          data['conversation'] ?? 'Trial expired',
          ApiErrorCode.trialExpired,
        );
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
      AppLogger.error('Extract image error', e is Exception ? e : null);
      throw ApiException(
        'Failed to extract conversation from image',
        ApiErrorCode.server,
      );
    }
  }

  Future<String> analyzeProfile(File imageFile) async {
    try {
      final token = await AuthService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/analyze-profile/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeJson(response.body);

      if (data['success'] == false) {
        throw ApiException(
          data['profile_info'] ?? 'Failed to analyze profile',
          ApiErrorCode.server,
        );
      }

      return data['profile_info'] ?? '';
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      AppLogger.error('Analyze profile error', e is Exception ? e : null);
      throw ApiException('Failed to analyze profile image', ApiErrorCode.server);
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

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      AppLogger.error('Failed to decode JSON response', e is Exception ? e : null);
    }
    return <String, dynamic>{'success': false, 'message': 'Invalid server response'};
  }

  ApiErrorCode _mapErrorCode(String? error) {
    switch (error) {
      case 'insufficient_credits':
        return ApiErrorCode.insufficientCredits;
      case 'trial_expired':
        return ApiErrorCode.trialExpired;
      default:
        return ApiErrorCode.unknown;
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final ApiErrorCode code;
  ApiException(this.message, [this.code = ApiErrorCode.unknown]);

  @override
  String toString() => message;
}

enum ApiErrorCode {
  insufficientCredits,
  trialExpired,
  network,
  server,
  unknown,
}
