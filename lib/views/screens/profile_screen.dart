import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _openPolicy(String policyType, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyViewerScreen(
          title: title,
          policyType: policyType,
        ),
      ),
    );
  }

  void _openDeleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final appState = AppStateScope.of(context);
    final user = appState.user;
    final email = user?.email ?? '';
    final username = user?.username ?? '';
    final memberName = username.isNotEmpty
        ? username
        : (email.isNotEmpty ? email.split('@').first : 'Guest');
    final isLightMode = appState.themeMode == AppThemeMode.premiumLightGold;
    final ambienceLabel = isLightMode ? 'Royal Romance' : 'Midnight Gold';
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
        title: const Text('Profile'),
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
                        const Text(
                          'Help & Policies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.report_outlined),
                          title: const Text('Report an Issue'),
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
                          title: const Text('Privacy Policy'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('privacy', 'Privacy Policy');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Terms of Use'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('terms', 'Terms of Use');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: const Text('Refund Policy'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _openPolicy('refund', 'Refund Policy');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Delete Account'),
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
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(Icons.person_outline, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.isLoggedIn
                              ? 'Member: $memberName'
                              : 'Guest Preview',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.isLoggedIn ? 'Member Access' : 'Preview Access',
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
                        const Text(
                          'Membership Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.isSubscribed ? 'Active - Elite' : 'Inactive',
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
                    child: Text(appState.isSubscribed ? 'Manage' : 'Subscribe'),
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
                    title: const Text('Ambience'),
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
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Security Settings'),
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
                    title: const Text('Sign out'),
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
