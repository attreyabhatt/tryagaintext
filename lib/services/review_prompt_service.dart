import 'package:shared_preferences/shared_preferences.dart';

enum ReviewTriggerReason { milestone3, milestone50, comeback }

class ReviewPromptDecision {
  final bool shouldShow;
  final ReviewTriggerReason? reason;
  final String headline;
  final String subtext;
  final String positiveLabel;

  const ReviewPromptDecision._({
    required this.shouldShow,
    required this.reason,
    required this.headline,
    required this.subtext,
    required this.positiveLabel,
  });

  const ReviewPromptDecision.none()
    : this._(
        shouldShow: false,
        reason: null,
        headline: '',
        subtext: '',
        positiveLabel: '',
      );

  factory ReviewPromptDecision.qualityCheck({
    required ReviewTriggerReason reason,
  }) {
    return ReviewPromptDecision._(
      shouldShow: true,
      reason: reason,
      headline: 'Quality Check',
      subtext: 'Is the AI helping your conversation flow?',
      positiveLabel: 'Results are Solid',
    );
  }

  factory ReviewPromptDecision.systemStatus({
    required ReviewTriggerReason reason,
  }) {
    return ReviewPromptDecision._(
      shouldShow: true,
      reason: reason,
      headline: 'System Status',
      subtext: 'You have generated over 50 responses. Still accurate?',
      positiveLabel: 'Analysis is Perfect',
    );
  }

  factory ReviewPromptDecision.redemption({
    required ReviewTriggerReason reason,
  }) {
    return ReviewPromptDecision._(
      shouldShow: true,
      reason: reason,
      headline: 'Has the analysis improved?',
      subtext: 'Tell us if the responses are better now.',
      positiveLabel: 'Yes, Much Better',
    );
  }
}

class ReviewPromptService {
  static const String keyHasLaunchedGoogleReview = 'has_launched_google_review';
  static const String keyReviewTotalCopies = 'review_total_copies';
  static const String keyReviewPromptedMilestones = 'review_prompted_milestones';
  static const String keyLastNegativeFeedbackTimeMs =
      'last_negative_feedback_time_ms';
  static const String keyLastZeroCreditsUtcDay = 'last_zero_credits_utc_day';

  static const int _milestone3 = 3;
  static const int _milestone50 = 50;
  static const Duration _negativeSnoozeDuration = Duration(days: 60);

  Future<ReviewPromptDecision> recordCopyAndGetDecision({
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = now ?? DateTime.now();
    final totalCopies = (prefs.getInt(keyReviewTotalCopies) ?? 0) + 1;
    await prefs.setInt(keyReviewTotalCopies, totalCopies);

    if (!_canShowPromptNow(
      prefs: prefs,
      now: timestamp,
      totalCopies: totalCopies,
    )) {
      return const ReviewPromptDecision.none();
    }

    final promptedMilestones = _getPromptedMilestones(prefs);
    final hasRedeemedNegative = _isNegativeRedemptionReady(
      prefs: prefs,
      now: timestamp,
      totalCopies: totalCopies,
    );

    if (totalCopies >= _milestone3 && !promptedMilestones.contains(_milestone3)) {
      promptedMilestones.add(_milestone3);
      await _savePromptedMilestones(prefs, promptedMilestones);
      return ReviewPromptDecision.qualityCheck(
        reason: ReviewTriggerReason.milestone3,
      );
    }

    if (totalCopies >= _milestone50 &&
        !promptedMilestones.contains(_milestone50)) {
      promptedMilestones.add(_milestone50);
      await _savePromptedMilestones(prefs, promptedMilestones);
      if (hasRedeemedNegative) {
        return ReviewPromptDecision.redemption(
          reason: ReviewTriggerReason.milestone50,
        );
      }
      return ReviewPromptDecision.systemStatus(
        reason: ReviewTriggerReason.milestone50,
      );
    }

    return const ReviewPromptDecision.none();
  }

  Future<ReviewPromptDecision> recordNeedReplySuccessAndGetDecision({
    required bool isSubscribed,
    DateTime? now,
  }) async {
    if (isSubscribed) {
      return const ReviewPromptDecision.none();
    }

    final prefs = await SharedPreferences.getInstance();
    final timestamp = now ?? DateTime.now();
    final totalCopies = prefs.getInt(keyReviewTotalCopies) ?? 0;
    if (!_canShowPromptNow(
      prefs: prefs,
      now: timestamp,
      totalCopies: totalCopies,
    )) {
      return const ReviewPromptDecision.none();
    }

    final yesterdayUtc = _toUtcDayString(
      timestamp.toUtc().subtract(const Duration(days: 1)),
    );
    final lastZeroDay = prefs.getString(keyLastZeroCreditsUtcDay);
    if (lastZeroDay != yesterdayUtc) {
      return const ReviewPromptDecision.none();
    }
    final hasRedeemedNegative = _isNegativeRedemptionReady(
      prefs: prefs,
      now: timestamp,
      totalCopies: totalCopies,
    );
    if (hasRedeemedNegative) {
      return ReviewPromptDecision.redemption(
        reason: ReviewTriggerReason.comeback,
      );
    }
    return ReviewPromptDecision.qualityCheck(
      reason: ReviewTriggerReason.comeback,
    );
  }

  Future<void> markGoogleReviewLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasLaunchedGoogleReview, true);
  }

  Future<void> markNegativeFeedbackSubmitted({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = now ?? DateTime.now();
    final millis = timestamp.millisecondsSinceEpoch.toString();
    // Store as String to avoid platform codec edge cases with large integer values.
    await prefs.setString(keyLastNegativeFeedbackTimeMs, millis);
  }

  Future<void> recordZeroCreditsDayIfNeeded({
    required bool isSubscribed,
    required int? freeDailyCreditsRemaining,
    DateTime? now,
  }) async {
    if (isSubscribed || freeDailyCreditsRemaining != 0) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final timestamp = now ?? DateTime.now();
    final utcDay = _toUtcDayString(timestamp.toUtc());
    await prefs.setString(keyLastZeroCreditsUtcDay, utcDay);
  }

  bool _canShowPromptNow({
    required SharedPreferences prefs,
    required DateTime now,
    required int totalCopies,
  }) {
    if (prefs.getBool(keyHasLaunchedGoogleReview) ?? false) {
      return false;
    }
    return _passesNegativeSnoozeGate(
      prefs: prefs,
      now: now,
      totalCopies: totalCopies,
    );
  }

  bool _passesNegativeSnoozeGate({
    required SharedPreferences prefs,
    required DateTime now,
    required int totalCopies,
  }) {
    final lastNegativeMs = _getStoredMillis(
      prefs,
      keyLastNegativeFeedbackTimeMs,
    );
    if (lastNegativeMs == null) {
      return true;
    }
    final elapsedMs = now.millisecondsSinceEpoch - lastNegativeMs;
    if (elapsedMs < _negativeSnoozeDuration.inMilliseconds) {
      return false;
    }
    return totalCopies >= _milestone50;
  }

  bool _isNegativeRedemptionReady({
    required SharedPreferences prefs,
    required DateTime now,
    required int totalCopies,
  }) {
    final lastNegativeMs = _getStoredMillis(
      prefs,
      keyLastNegativeFeedbackTimeMs,
    );
    if (lastNegativeMs == null) {
      return false;
    }
    final elapsedMs = now.millisecondsSinceEpoch - lastNegativeMs;
    return elapsedMs >= _negativeSnoozeDuration.inMilliseconds &&
        totalCopies >= _milestone50;
  }

  Set<int> _getPromptedMilestones(SharedPreferences prefs) {
    final stored = prefs.getStringList(keyReviewPromptedMilestones) ?? [];
    return stored.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _savePromptedMilestones(
    SharedPreferences prefs,
    Set<int> milestones,
  ) async {
    final list = milestones.toList()..sort();
    final values = list.map((value) => value.toString()).toList();
    await prefs.setStringList(keyReviewPromptedMilestones, values);
  }

  int? _getStoredMillis(SharedPreferences prefs, String key) {
    final fromInt = prefs.getInt(key);
    if (fromInt != null) {
      return fromInt;
    }
    final fromString = prefs.getString(key);
    if (fromString == null || fromString.trim().isEmpty) {
      return null;
    }
    return int.tryParse(fromString.trim());
  }

  String _toUtcDayString(DateTime utc) {
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }
}
