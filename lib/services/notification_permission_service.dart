import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service.dart';

class NotificationPermissionService {
  static const String _lastSoftPromptAtMsKey = 'notif_soft_prompt_last_at_ms';
  static const String _nativePromptRequestedKey =
      'notif_native_prompt_requested';
  static const Duration _softPromptCooldown = Duration(days: 7);
  static bool _isPromptOpen = false;

  static bool get _supportsCurrentPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> maybePromptAfterFirstSuccess(BuildContext context) async {
    if (!_supportsCurrentPlatform || _isPromptOpen) return;

    final granted = await PushNotificationService.isPermissionGranted();
    if (granted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasAttemptedNativePrompt =
        prefs.getBool(_nativePromptRequestedKey) ?? false;
    if (hasAttemptedNativePrompt) return;

    final canRequest = await PushNotificationService.canRequestPermission();
    if (!canRequest) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastPromptAtMs = prefs.getInt(_lastSoftPromptAtMsKey);
    if (lastPromptAtMs != null) {
      final elapsedMs = nowMs - lastPromptAtMs;
      if (elapsedMs < _softPromptCooldown.inMilliseconds) {
        return;
      }
    }

    if (!context.mounted) return;
    _isPromptOpen = true;
    bool? shouldRequest;
    try {
      shouldRequest = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Stay in Control \u{2728}'),
            content: const Text(
              'Enable notifications to get refill reminders and timely conversation nudges.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Enable'),
              ),
            ],
          );
        },
      );
    } finally {
      _isPromptOpen = false;
    }

    if (shouldRequest == true) {
      await prefs.setBool(_nativePromptRequestedKey, true);
      await PushNotificationService.requestPermissionFromSystem();
      return;
    }

    await prefs.setInt(_lastSoftPromptAtMsKey, nowMs);
  }
}
