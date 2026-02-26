import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flirtfix/l10n/gen/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'policy_viewer_screen.dart';
import 'pricing_screen.dart';
import 'report_issue_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _localeLabel(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    return switch (locale.languageCode) {
      'en' => l10n.languageEnglish,
      'es' => l10n.languageSpanish,
      _ => locale.languageCode.toUpperCase(),
    };
  }

  Future<void> _signOut() async {
    await AppStateScope.of(context).logout();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppStateScope.of(context).refreshUserData();
    });
  }

  void _openPolicy(String policyType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyViewerScreen(policyType: policyType),
      ),
    );
  }

  void _openDeleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeleteAccountScreen()),
    );
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
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    final appState = AppStateScope.of(context);
    final user = appState.user;
    final email = user?.email ?? '';
    final username = user?.username ?? '';
    final memberName = username.isNotEmpty
        ? username
        : (email.isNotEmpty ? email.split('@').first : l10n.profileGuest);
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
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileHelpPolicies,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.report_outlined),
                          title: Text(l10n.reportIssueTitle),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportIssueScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: Text(l10n.policyPrivacyTitle),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('privacy');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(l10n.policyTermsTitle),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('terms');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(l10n.policyRefundTitle),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('refund');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: Text(l10n.deleteAccountTitle),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openDeleteAccount();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [cardShadow],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.isLoggedIn
                              ? l10n.profileMember(memberName)
                              : l10n.profileGuestPreview,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.isLoggedIn
                              ? l10n.profileMemberAccess
                              : l10n.profilePreviewAccess,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [cardShadow],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileMembershipStatus,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.isSubscribed
                              ? l10n.profileMembershipActive
                              : l10n.profileMembershipInactive,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PricingScreen(),
                        ),
                      );
                    },
                    child: Text(
                      appState.isSubscribed
                          ? l10n.profileManage
                          : l10n.profileSubscribe,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: Text(l10n.profileSecuritySettings),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: Text(l10n.profileSignOut),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _signOut();
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
