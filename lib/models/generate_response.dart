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
  // Blurred cliff fields
  final bool? isLocked;
  final int? lockedReplyId;
  final List<String>? lockedPreview;
  final bool? hasPendingUnlock;
  // Free daily credit fields
  final int? freeDailyCreditsRemaining;
  final int? freeDailyCreditsLimit;

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
    this.isLocked,
    this.lockedReplyId,
    this.lockedPreview,
    this.hasPendingUnlock,
    this.freeDailyCreditsRemaining,
    this.freeDailyCreditsLimit,
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
      isLocked: json['is_locked'],
      lockedReplyId: json['locked_reply_id'],
      lockedPreview: (json['locked_preview'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      hasPendingUnlock: json['has_pending_unlock'],
      freeDailyCreditsRemaining: json['free_daily_credits_remaining'],
      freeDailyCreditsLimit: json['free_daily_credits_limit'],
    );
  }
}
