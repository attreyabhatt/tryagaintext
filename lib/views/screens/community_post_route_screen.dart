import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import 'community_post_detail_screen.dart';
import 'settings_screen.dart';

class CommunityPostRouteScreen extends StatefulWidget {
  final int postId;

  const CommunityPostRouteScreen({super.key, required this.postId});

  @override
  State<CommunityPostRouteScreen> createState() =>
      _CommunityPostRouteScreenState();
}

class _CommunityPostRouteScreenState extends State<CommunityPostRouteScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _navigated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPostAndOpen();
  }

  Future<void> _loadPostAndOpen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await _api.getCommunityPostDetail(widget.postId);
      if (!mounted || _navigated) return;
      _navigated = true;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CommunityPostDetailScreen(post: post),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/icons/appstore_transparent.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: tt.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l10n.communityTitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
                color: Colors.transparent,
              ),
              child: Icon(
                Icons.settings_outlined,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 46,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.communityUnableToOpenPost,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadPostAndOpen,
                      child: Text(l10n.communityTryAgain),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
