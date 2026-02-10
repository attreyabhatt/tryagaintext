import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flirtfix/services/review_prompt_service.dart';

void main() {
  late ReviewPromptService service;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = ReviewPromptService();
  });

  test('milestone 3 prompt appears on third successful copy', () async {
    final now = DateTime.utc(2026, 2, 10, 12);

    final first = await service.recordCopyAndGetDecision(now: now);
    final second = await service.recordCopyAndGetDecision(now: now);
    final third = await service.recordCopyAndGetDecision(now: now);

    expect(first.shouldShow, isFalse);
    expect(second.shouldShow, isFalse);
    expect(third.shouldShow, isTrue);
    expect(third.reason, ReviewTriggerReason.milestone3);
    expect(third.headline, 'Quality Check');
  });

  test('milestone 50 prompt recovers when exact count was skipped', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReviewPromptService.keyReviewTotalCopies: 55,
      ReviewPromptService.keyReviewPromptedMilestones: <String>['3'],
    });
    service = ReviewPromptService();

    final decision = await service.recordCopyAndGetDecision(
      now: DateTime.utc(2026, 2, 10, 13),
    );

    expect(decision.shouldShow, isTrue);
    expect(decision.reason, ReviewTriggerReason.milestone50);
  });

  test('positive path marks flow complete forever', () async {
    final now = DateTime.utc(2026, 2, 10, 14);
    await service.markGoogleReviewLaunched();

    final copyDecision = await service.recordCopyAndGetDecision(now: now);
    final comebackDecision = await service.recordNeedReplySuccessAndGetDecision(
      isSubscribed: false,
      now: now,
    );

    expect(copyDecision.shouldShow, isFalse);
    expect(comebackDecision.shouldShow, isFalse);
  });

  test('negative feedback snoozes prompts for 60 days', () async {
    final now = DateTime.utc(2026, 2, 10, 15);
    final fiftyNineDaysAgo = now.subtract(const Duration(days: 59));

    SharedPreferences.setMockInitialValues(<String, Object>{
      ReviewPromptService.keyReviewTotalCopies: 80,
      ReviewPromptService.keyLastNegativeFeedbackTimeMs:
          fiftyNineDaysAgo.millisecondsSinceEpoch,
      ReviewPromptService.keyReviewPromptedMilestones: <String>['3'],
    });
    service = ReviewPromptService();

    final decision = await service.recordCopyAndGetDecision(now: now);
    expect(decision.shouldShow, isFalse);
  });

  test('negative feedback allows redemption after 60 days and 50 copies', () async {
    final now = DateTime.utc(2026, 2, 10, 16);
    final sixtyOneDaysAgo = now.subtract(const Duration(days: 61));

    SharedPreferences.setMockInitialValues(<String, Object>{
      ReviewPromptService.keyReviewTotalCopies: 50,
      ReviewPromptService.keyLastNegativeFeedbackTimeMs:
          sixtyOneDaysAgo.millisecondsSinceEpoch,
      ReviewPromptService.keyReviewPromptedMilestones: <String>['3'],
    });
    service = ReviewPromptService();

    final decision = await service.recordCopyAndGetDecision(now: now);
    expect(decision.shouldShow, isTrue);
    expect(decision.reason, ReviewTriggerReason.milestone50);
    expect(decision.headline, 'Has the analysis improved?');
  });

  test('comeback prompt can trigger again on same day', () async {
    final now = DateTime.utc(2026, 2, 10, 17);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues(<String, Object>{
      ReviewPromptService.keyReviewTotalCopies: 10,
      ReviewPromptService.keyLastZeroCreditsUtcDay: yesterdayKey,
    });
    service = ReviewPromptService();

    final first = await service.recordNeedReplySuccessAndGetDecision(
      isSubscribed: false,
      now: now,
    );
    final second = await service.recordNeedReplySuccessAndGetDecision(
      isSubscribed: false,
      now: now.add(const Duration(hours: 1)),
    );

    expect(first.shouldShow, isTrue);
    expect(first.reason, ReviewTriggerReason.comeback);
    expect(second.shouldShow, isTrue);
    expect(second.reason, ReviewTriggerReason.comeback);
  });

  test('negative users must also reach 50 copies before comeback re-ask', () async {
    final now = DateTime.utc(2026, 2, 10, 18);
    final yesterday = now.subtract(const Duration(days: 1));
    final sixtyOneDaysAgo = now.subtract(const Duration(days: 61));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues(<String, Object>{
      ReviewPromptService.keyReviewTotalCopies: 40,
      ReviewPromptService.keyLastZeroCreditsUtcDay: yesterdayKey,
      ReviewPromptService.keyLastNegativeFeedbackTimeMs:
          sixtyOneDaysAgo.millisecondsSinceEpoch,
    });
    service = ReviewPromptService();

    final decision = await service.recordNeedReplySuccessAndGetDecision(
      isSubscribed: false,
      now: now,
    );

    expect(decision.shouldShow, isFalse);
  });
}
