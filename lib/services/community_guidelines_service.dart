import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityGuidelinesService {
  static const _acceptedKey = 'community_guidelines_accepted';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedKey, true);
  }

  /// Shows the guidelines dialog if not yet accepted.
  /// Returns true if the user accepts or has already accepted.
  static Future<bool> ensureAccepted(BuildContext context) async {
    if (await hasAccepted()) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Community Guidelines'),
          content: const Text(
            'By posting or commenting, you agree to our Community Guidelines:\n\n'
            '\u2022 Be respectful and kind to others\n'
            '\u2022 No spam, harassment, or hate speech\n'
            '\u2022 No sharing of personal information\n'
            '\u2022 Keep content relevant and appropriate\n\n'
            'Violations may result in content removal or account suspension.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: cs.primary),
              child: const Text('I Agree'),
            ),
          ],
        );
      },
    );

    if (accepted == true) {
      await markAccepted();
      return true;
    }
    return false;
  }
}
