import 'user.dart';

// models/auth_response.dart
class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final int? chatCredits;
  final bool? isSubscribed;
  final String? subscriptionExpiry;
  final int? subscriberWeeklyRemaining;
  final int? subscriberWeeklyLimit;
  final String? error;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.chatCredits,
    this.isSubscribed,
    this.subscriptionExpiry,
    this.subscriberWeeklyRemaining,
    this.subscriberWeeklyLimit,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      chatCredits: json['chat_credits'],
      isSubscribed: json['is_subscribed'],
      subscriptionExpiry: json['subscription_expiry'],
      subscriberWeeklyRemaining: json['subscriber_weekly_remaining'],
      subscriberWeeklyLimit: json['subscriber_weekly_limit'],
      error: json['error'],
    );
  }
}
