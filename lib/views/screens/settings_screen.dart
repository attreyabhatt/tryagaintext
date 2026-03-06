import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flirtfix/l10n/gen/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/local_notification_service.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showTestMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await LocalNotificationService.requestPermission();
    _showTestMessage(
      granted
          ? 'Notification permission granted.'
          : 'Permission not granted or already blocked.',
    );
  }

  Future<void> _sendDailyRefillNow() async {
    await LocalNotificationService.showDailyRefillNow();
    _showTestMessage('Sent daily refill notification.');
  }

  Future<void> _scheduleDailyRefillIn15s() async {
    await LocalNotificationService.scheduleDailyRefillReminder(
      delay: const Duration(seconds: 15),
      forceReschedule: true,
    );
    _showTestMessage('Scheduled daily refill notification in 15 seconds.');
  }

  Future<void> _sendGuestSignupNudgeNow() async {
    await LocalNotificationService.showGuestSignupNudgeNow();
    _showTestMessage('Sent guest signup nudge notification.');
  }

  Future<void> _scheduleGuestSignupNudgeIn15s() async {
    await LocalNotificationService.scheduleGuestSignupNudge(
      delay: const Duration(seconds: 15),
      forceReschedule: true,
    );
    _showTestMessage('Scheduled guest signup nudge in 15 seconds.');
  }

  Future<void> _sendUpgradeNudgeNow() async {
    await LocalNotificationService.showUpgradeNudgeNow();
    _showTestMessage('Sent upgrade nudge notification.');
  }

  Future<void> _scheduleUpgradeNudgeIn15s() async {
    await LocalNotificationService.scheduleUpgradeNudge(
      delay: const Duration(seconds: 15),
      forceReschedule: true,
    );
    _showTestMessage('Scheduled upgrade nudge in 15 seconds.');
  }

  Future<void> _cancelV1CampaignNotifications() async {
    await LocalNotificationService.cancelV1CampaignNotifications();
    _showTestMessage('Canceled v1 campaign notifications.');
  }

  Future<void> _showPendingNotificationIds() async {
    final ids = await LocalNotificationService.pendingNotificationIds();
    if (ids.isEmpty) {
      _showTestMessage('No pending local notifications.');
      return;
    }
    _showTestMessage('Pending local notification IDs: ${ids.join(', ')}');
  }

  Future<void> _cancelAllTestNotifications() async {
    await LocalNotificationService.cancelAll();
    _showTestMessage('Canceled all local notifications.');
  }

  String _localeLabel(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    return switch (locale.languageCode) {
      'en' => l10n.languageEnglish,
      'es' => l10n.languageSpanish,
      'pt' => l10n.languagePortuguese,
      'de' => l10n.languageGerman,
      'fr' => l10n.languageFrench,
      _ => locale.languageCode.toUpperCase(),
    };
  }

  Future<void> _openLanguagePicker() async {
    final appState = AppStateScope.of(context);
    final l10n = context.l10n;
    final supportedLocales = AppLocalizations.supportedLocales;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final currentCode = appState.localeOverride?.languageCode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageSystem),
                trailing: currentCode == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, 'system'),
              ),
              ...supportedLocales.map((locale) {
                final code = locale.languageCode;
                return ListTile(
                  title: Text(_localeLabel(context, locale)),
                  trailing: currentCode == code
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, code),
                );
              }),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    if (choice == 'system') {
      await appState.setLocaleOverride(null);
      return;
    }
    await appState.setLocaleOverride(Locale(choice));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final appState = AppStateScope.of(context);
    final isLightMode = appState.themeMode == AppThemeMode.premiumLightGold;
    final ambienceLabel = isLightMode
        ? l10n.profileAmbienceRoyalRomance
        : l10n.profileAmbienceMidnightGold;
    final isLight = theme.brightness == Brightness.light;
    final cardShadow = isLight
        ? BoxShadow(
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [cardShadow],
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.light_mode_outlined),
                    title: Text(l10n.profileAmbience),
                    subtitle: Text(ambienceLabel),
                    value: isLightMode,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      appState.setThemeMode(
                        value
                            ? AppThemeMode.premiumLightGold
                            : AppThemeMode.premiumDarkNeonGold,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(l10n.profileLanguage),
                    subtitle: Text(
                      appState.localeOverride == null
                          ? l10n.languageSystem
                          : _localeLabel(context, appState.localeOverride!),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _openLanguagePicker();
                    },
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Debug: v1 Notification Tests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'These buttons use the exact copy wired for Daily Refill and Conversion Nudges.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _requestNotificationPermission,
                      child: const Text('Request Notification Permission'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _sendDailyRefillNow,
                      child: const Text('Send Daily Refill Now'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _scheduleDailyRefillIn15s,
                      child: const Text('Schedule Daily Refill (15s)'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _sendGuestSignupNudgeNow,
                      child: const Text('Send Signup Nudge Now'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _scheduleGuestSignupNudgeIn15s,
                      child: const Text('Schedule Signup Nudge (15s)'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _sendUpgradeNudgeNow,
                      child: const Text('Send Upgrade Nudge Now'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _scheduleUpgradeNudgeIn15s,
                      child: const Text('Schedule Upgrade Nudge (15s)'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _cancelV1CampaignNotifications,
                      child: const Text('Cancel v1 Campaign Notifications'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _showPendingNotificationIds,
                      child: const Text('Show Pending Notification IDs'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _cancelAllTestNotifications,
                      child: const Text('Cancel All Local Notifications'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

