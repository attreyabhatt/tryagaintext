import 'user.dart';

// models/auth_response.dart
class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final int? chatCredits;
  final String? error;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.chatCredits,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      chatCredits: json['chat_credits'],
      error: json['error'],
    );
  }
}
