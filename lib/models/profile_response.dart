// models/profile_response.dart

import 'user.dart';

class ProfileResponse {
  final bool success;
  final User? user;
  final int? chatCredits;
  final bool? isSubscribed;
  final String? subscriptionExpiry;
  final int? subscriberWeeklyRemaining;
  final int? subscriberWeeklyLimit;
  final String? error;

  ProfileResponse({
    required this.success,
    this.user,
    this.chatCredits,
    this.isSubscribed,
    this.subscriptionExpiry,
    this.subscriberWeeklyRemaining,
    this.subscriberWeeklyLimit,
    this.error,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
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
