import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import 'community_post_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
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
                      'Unable to open this post right now.',
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
                      child: const Text('Try again'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
