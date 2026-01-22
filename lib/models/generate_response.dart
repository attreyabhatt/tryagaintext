// models/generate_response.dart
class GenerateResponse {
  final bool success;
  final String? reply;
  final int? creditsRemaining;
  final bool? isSubscribed;
  final String? subscriptionExpiry;
  final int? subscriberWeeklyRemaining;
  final int? subscriberWeeklyLimit;
  final String? error;
  final String? message;
  final bool? isTrial;
  final bool? trialUsed;

  GenerateResponse({
    required this.success,
    this.reply,
    this.creditsRemaining,
    this.isSubscribed,
    this.subscriptionExpiry,
    this.subscriberWeeklyRemaining,
    this.subscriberWeeklyLimit,
    this.error,
    this.message,
    this.isTrial,
    this.trialUsed,
  });

  factory GenerateResponse.fromJson(Map<String, dynamic> json) {
    return GenerateResponse(
      success: json['success'] ?? false,
      reply: json['reply'],
      creditsRemaining: json['credits_remaining'],
      isSubscribed: json['is_subscribed'],
      subscriptionExpiry: json['subscription_expiry'],
      subscriberWeeklyRemaining: json['subscriber_weekly_remaining'],
      subscriberWeeklyLimit: json['subscriber_weekly_limit'],
      error: json['error'],
      message: json['message'],
      isTrial: json['is_trial'],
      trialUsed: json['trial_used'],
    );
  }
}
