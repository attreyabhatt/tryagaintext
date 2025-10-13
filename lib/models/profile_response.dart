// models/profile_response.dart

import 'user.dart';

class ProfileResponse {
  final bool success;
  final User? user;
  final int? chatCredits;
  final String? error;

  ProfileResponse({
    required this.success,
    this.user,
    this.chatCredits,
    this.error,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      chatCredits: json['chat_credits'],
      error: json['error'],
    );
  }
}
