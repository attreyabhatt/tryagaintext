// models/generate_response.dart
class GenerateResponse {
  final bool success;
  final String? reply;
  final int? creditsRemaining;
  final String? error;
  final String? message;
  final bool? isTrial;
  final bool? trialUsed;

  GenerateResponse({
    required this.success,
    this.reply,
    this.creditsRemaining,
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
      error: json['error'],
      message: json['message'],
      isTrial: json['is_trial'],
      trialUsed: json['trial_used'],
    );
  }
}
