import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/generate_response.dart';
import '../models/payment_history.dart';
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
    final deviceFingerprint = await AuthService.getOrCreateDeviceFingerprint();
    headers['X-Device-Fingerprint'] = deviceFingerprint;
    // Backward compatibility for existing backend parsing.
    headers['X-Guest-Id'] = deviceFingerprint;

    return headers;
  }

  Future<List<Suggestion>> generate({
    required String lastText,
    required String situation,
    String herInfo = '',
    required String tone,
    String customInstructions = '',
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
          'custom_instructions': customInstructions,
        }),
      );

      AppLogger.debug(
        'POST $baseUrl/api/generate/ -> ${response.statusCode} '
        '${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}',
      );

      final data = _decodeJson(response.body);
      await AuthService.updateSubscriptionFromPayload(data);
      final generateResponse = GenerateResponse.fromJson(data);

      if (!generateResponse.success) {
        // Handle has_pending_unlock — carry locked reply data in exception
        if (generateResponse.error == 'has_pending_unlock') {
          throw ApiException(
            generateResponse.message ?? 'You have a hidden reply waiting!',
            ApiErrorCode.hasPendingUnlock,
            generateResponse.lockedReplyId,
            generateResponse.lockedPreview,
          );
        }
        throw ApiException(
          generateResponse.message ?? 'Generation failed',
          _mapErrorCode(generateResponse.error),
        );
      }

      // Handle locked response (blurred cliff — first time at limit)
      if (generateResponse.isLocked == true) {
        final previews = generateResponse.lockedPreview ?? [];
        return List.generate(
          previews.length,
          (i) => Suggestion(
            message: previews[i],
            confidence: 0.8,
            isLocked: true,
            blurPreview: previews[i],
            lockedReplyId: generateResponse.lockedReplyId,
          ),
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
      throw ApiException(
        'Network error. Please try again.',
        ApiErrorCode.network,
      );
    }
  }

  Future<String> extractFromImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();
      final deviceFingerprint =
          await AuthService.getOrCreateDeviceFingerprint();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/extract-image/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      request.headers['X-Device-Fingerprint'] = deviceFingerprint;
      // Backward compatibility for existing backend parsing.
      request.headers['X-Guest-Id'] = deviceFingerprint;

      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.debug(
        'POST $baseUrl/api/extract-image/ -> ${response.statusCode} '
        '${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}',
      );
      final data = _decodeJson(response.body);
      await AuthService.updateSubscriptionFromPayload(data);
      await AuthService.updateSubscriptionFromPayload(data);

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
      final deviceFingerprint =
          await AuthService.getOrCreateDeviceFingerprint();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/analyze-profile/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      request.headers['X-Device-Fingerprint'] = deviceFingerprint;
      // Backward compatibility for existing backend parsing.
      request.headers['X-Guest-Id'] = deviceFingerprint;

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
      await AuthService.updateSubscriptionFromPayload(data);

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
      throw ApiException(
        'Failed to analyze profile image',
        ApiErrorCode.server,
      );
    }
  }

  Future<bool> reportIssue({
    required String reason,
    required String title,
    required String subject,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/report/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reason': reason,
          'title': title,
          'subject': subject,
          'email': email,
        }),
      );

      final data = _decodeJson(response.body);
      return data['success'] == true;
    } catch (e) {
      AppLogger.error('Report issue error', e is Exception ? e : null);
      return false;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/change-password/'),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = _decodeJson(response.body);
      if (data['success'] == true) {
        return null;
      }

      return data['error']?.toString() ?? 'Password update failed';
    } catch (e) {
      AppLogger.error('Change password error', e is Exception ? e : null);
      return 'Network error. Please try again.';
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/delete-account/'),
        headers: headers,
        body: jsonEncode({'password': password}),
      );

      final data = _decodeJson(response.body);
      if (data['success'] == true) {
        return true;
      }

      // Extract error message from response
      final errorMsg = data['error']?.toString() ?? 'Account deletion failed';
      throw ApiException(errorMsg, ApiErrorCode.server);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      AppLogger.error('Delete account error', e is Exception ? e : null);
      throw ApiException(
        'Network error. Please try again.',
        ApiErrorCode.network,
      );
    }
  }

  Future<int?> confirmGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? purchaseTime,
    double? price,
    String? currency,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/google-play/purchase/'),
        headers: headers,
        body: jsonEncode({
          'product_id': productId,
          'purchase_token': purchaseToken,
          'order_id': orderId,
          'purchase_time': purchaseTime,
          'price': price,
          'currency': currency,
        }),
      );

      AppLogger.debug(
        'Google Play purchase response: ${response.statusCode} ${response.body}',
      );

      final data = _decodeJson(response.body);
      if (data['success'] == true) {
        return data['credits_remaining'] as int?;
      }

      AppLogger.error(
        'Google Play purchase failed',
        Exception(data['error']?.toString() ?? 'unknown error'),
      );
      return null;
    } catch (e) {
      AppLogger.error('Google Play purchase error', e is Exception ? e : null);
      return null;
    }
  }

  Future<String?> requestPasswordReset({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password-reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = _decodeJson(response.body);
      if (data['success'] == true) {
        return null;
      }

      return data['error']?.toString() ?? 'Password reset failed';
    } catch (e) {
      AppLogger.error('Password reset error', e is Exception ? e : null);
      return 'Network error. Please try again.';
    }
  }

  Future<bool> confirmGooglePlaySubscription({
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/google-play/verify-subscription/'),
        headers: headers,
        body: jsonEncode({
          'product_id': productId,
          'purchase_token': purchaseToken,
        }),
      );

      AppLogger.debug(
        'Google Play subscription response: ${response.statusCode} ${response.body}',
      );

      final data = _decodeJson(response.body);
      await AuthService.updateSubscriptionFromPayload(data);

      if (data['success'] == true && data['is_subscribed'] == true) {
        return true;
      }

      AppLogger.error(
        'Google Play subscription failed',
        Exception(data['error']?.toString() ?? 'unknown error'),
      );
      return false;
    } catch (e) {
      AppLogger.error(
        'Google Play subscription error',
        e is Exception ? e : null,
      );
      return false;
    }
  }

  Future<bool> refreshSubscriptionStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: headers,
      );
      final data = _decodeJson(response.body);
      await AuthService.updateSubscriptionFromPayload(data);
      return data['is_subscribed'] == true;
    } catch (e) {
      AppLogger.error(
        'Refresh subscription status error',
        e is Exception ? e : null,
      );
      return false;
    }
  }

  Future<List<PaymentHistory>> getPaymentHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment-history/'),
        headers: headers,
      );

      final data = _decodeJson(response.body);
      if (data['success'] == true && data['purchases'] is List) {
        return (data['purchases'] as List)
            .map(
              (item) => PaymentHistory.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      AppLogger.error('Payment history error', e is Exception ? e : null);
      return [];
    }
  }

  Stream<Map<String, dynamic>> analyzeProfileStream(File imageFile) async* {
    final token = await AuthService.getToken();
    final deviceFingerprint = await AuthService.getOrCreateDeviceFingerprint();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/analyze-profile-stream/'),
    );
    request.headers['Accept'] = 'text/event-stream';
    if (token != null) {
      request.headers['Authorization'] = 'Token $token';
    }
    request.headers['X-Device-Fingerprint'] = deviceFingerprint;
    // Backward compatibility for existing backend parsing.
    request.headers['X-Guest-Id'] = deviceFingerprint;

    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw ApiException(
        'Request failed with status ${streamedResponse.statusCode}',
        ApiErrorCode.server,
      );
    }
    yield* _parseSseStream(streamedResponse.stream);
  }

  /// Generate openers directly from a profile image (no extraction step)
  Future<List<Suggestion>> generateOpenersFromImage(
    File imageFile, {
    String customInstructions = '',
  }) async {
    try {
      final token = await AuthService.getToken();
      final deviceFingerprint =
          await AuthService.getOrCreateDeviceFingerprint();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/generate-openers-from-image/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      request.headers['X-Device-Fingerprint'] = deviceFingerprint;
      // Backward compatibility for existing backend parsing.
      request.headers['X-Guest-Id'] = deviceFingerprint;

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      if (customInstructions.isNotEmpty) {
        request.fields['custom_instructions'] = customInstructions;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeJson(response.body);

      if (data['success'] == false) {
        if (data['error'] == 'has_pending_unlock') {
          final preview = (data['locked_preview'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          throw ApiException(
            data['message'] ?? 'You have a hidden reply waiting!',
            ApiErrorCode.hasPendingUnlock,
            data['locked_reply_id'] as int?,
            preview,
          );
        }
        if (data['error'] == 'insufficient_credits') {
          throw ApiException(
            data['message'] ?? 'No credits remaining',
            ApiErrorCode.insufficientCredits,
          );
        }
        if (data['error'] == 'trial_expired') {
          throw ApiException(
            data['message'] ?? 'Trial expired',
            ApiErrorCode.trialExpired,
          );
        }
        if (data['error'] == 'fair_use_exceeded') {
          throw ApiException(
            data['message'] ?? 'Daily limit reached',
            ApiErrorCode.fairUseExceeded,
          );
        }
        throw ApiException(
          data['message'] ?? 'Failed to generate openers',
          ApiErrorCode.server,
        );
      }

      // Update subscription info (including credits and daily limits)
      await AuthService.updateSubscriptionFromPayload(data);

      // Handle locked response (blurred cliff — first time at limit)
      if (data['is_locked'] == true) {
        final previews =
            (data['locked_preview'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final lockedId = data['locked_reply_id'] as int?;
        return List.generate(
          previews.length,
          (i) => Suggestion(
            message: previews[i],
            confidence: 0.8,
            isLocked: true,
            blurPreview: previews[i],
            lockedReplyId: lockedId,
          ),
        );
      }

      // Update stored credits if available (backwards compatibility)
      if (data['credits_remaining'] != null) {
        await AuthService.updateStoredCredits(data['credits_remaining']);
      }

      // Parse reply into suggestions
      return _parseReplyToSuggestions(data['reply'] ?? '');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      AppLogger.error(
        'Generate openers from image error',
        e is Exception ? e : null,
      );
      throw ApiException(
        'Failed to generate openers from image',
        ApiErrorCode.server,
      );
    }
  }

  /// Unlock a previously locked reply after subscribing
  Future<List<Suggestion>> unlockReply(int lockedReplyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/unlock-reply/'),
        headers: headers,
        body: jsonEncode({'locked_reply_id': lockedReplyId}),
      );

      final data = _decodeJson(response.body);
      if (data['success'] != true) {
        throw ApiException(
          data['message'] ?? 'Failed to unlock reply',
          _mapErrorCode(data['error']?.toString()),
        );
      }

      await AuthService.updateSubscriptionFromPayload(data);
      return _parseReplyToSuggestions(data['reply'] ?? '');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('Unlock reply error', e is Exception ? e : null);
      throw ApiException(
        'Network error. Please try again.',
        ApiErrorCode.network,
      );
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
            final whyItWorks = item['why_it_works']?.toString();
            final imageUrl = item['image_url']?.toString();

            if (message != null && message.trim().isNotEmpty) {
              double confidence = 0.8;
              if (confidenceScore is num) {
                confidence = confidenceScore.toDouble();
              }

              suggestions.add(
                Suggestion(
                  message: message.trim(),
                  confidence: confidence,
                  whyItWorks: whyItWorks?.trim().isNotEmpty == true
                      ? whyItWorks?.trim()
                      : null,
                  imageUrl: imageUrl?.trim().isNotEmpty == true
                      ? imageUrl?.trim()
                      : null,
                ),
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

  List<Suggestion> parseReplyToSuggestions(String reply) {
    return _parseReplyToSuggestions(reply);
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to decode JSON response',
        e is Exception ? e : null,
      );
    }
    return <String, dynamic>{
      'success': false,
      'message': 'Invalid server response',
    };
  }

  ApiErrorCode _mapErrorCode(String? error) {
    switch (error) {
      case 'insufficient_credits':
        return ApiErrorCode.insufficientCredits;
      case 'trial_expired':
        return ApiErrorCode.trialExpired;
      case 'subscription_required':
        return ApiErrorCode.insufficientCredits;
      case 'fair_use_exceeded':
        return ApiErrorCode.fairUseExceeded;
      case 'has_pending_unlock':
        return ApiErrorCode.hasPendingUnlock;
      default:
        return ApiErrorCode.unknown;
    }
  }

  Future<List<Suggestion>> getRecommendedOpeners({int count = 3}) async {
    try {
      final token = await AuthService.getToken();
      final deviceFingerprint =
          await AuthService.getOrCreateDeviceFingerprint();

      final response = await http.post(
        Uri.parse('$baseUrl/api/recommended-openers/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
          'X-Device-Fingerprint': deviceFingerprint,
          // Backward compatibility for existing backend parsing.
          'X-Guest-Id': deviceFingerprint,
        },
        body: jsonEncode({'count': count}),
      );

      final data = _decodeJson(response.body);

      if (data['success'] == false) {
        final code = _mapErrorCode(data['error']?.toString());
        throw ApiException(
          data['message'] ?? 'Failed to load recommended openers',
          code,
        );
      }

      await AuthService.updateSubscriptionFromPayload(data);

      if (data['credits_remaining'] != null) {
        await AuthService.updateStoredCredits(data['credits_remaining']);
      }

      final openers = data['openers'];
      if (openers is List) {
        return openers
            .whereType<Map<String, dynamic>>()
            .map((item) => Suggestion.fromJson(item))
            .toList();
      }

      return <Suggestion>[];
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      AppLogger.error('Recommended openers error', e is Exception ? e : null);
      throw ApiException(
        'Failed to load recommended openers',
        ApiErrorCode.server,
      );
    }
  }

  Stream<Map<String, dynamic>> _parseSseStream(
    Stream<List<int>> byteStream,
  ) async* {
    final buffer = StringBuffer();
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      while (true) {
        final data = buffer.toString();
        final splitIndex = data.indexOf('\n\n');
        if (splitIndex == -1) {
          break;
        }

        final eventBlock = data.substring(0, splitIndex);
        final remaining = data.substring(splitIndex + 2);
        buffer.clear();
        buffer.write(remaining);

        final lines = eventBlock.split('\n');
        final dataLines = <String>[];
        for (final line in lines) {
          if (line.startsWith('data:')) {
            dataLines.add(line.substring(5).trimLeft());
          }
        }

        if (dataLines.isEmpty) {
          continue;
        }

        final payload = dataLines.join('\n');
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          }
        } catch (e) {
          AppLogger.error(
            'Failed to decode SSE payload',
            e is Exception ? e : null,
          );
        }
      }
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final ApiErrorCode code;
  final int? lockedReplyId;
  final List<String>? lockedPreview;
  ApiException(
    this.message, [
    this.code = ApiErrorCode.unknown,
    this.lockedReplyId,
    this.lockedPreview,
  ]);

  @override
  String toString() => message;
}

enum ApiErrorCode {
  insufficientCredits,
  trialExpired,
  fairUseExceeded,
  hasPendingUnlock,
  network,
  server,
  unknown,
}
