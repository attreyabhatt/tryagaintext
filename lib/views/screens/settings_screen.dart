import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flirtfix/l10n/gen/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
          ],
        ),
      ),
    );
  }
}
