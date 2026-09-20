import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/reply_thread.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import 'archive_detail_screen.dart';
import 'login_screen.dart';

class ArchivesScreen extends StatefulWidget {
  final bool showAppBar;
  final Future<void> Function(ArchiveContinueRequest request)? onContinueRequested;
  final VoidCallback? onJumpHomeRequested;

  const ArchivesScreen({
    super.key,
    this.showAppBar = true,
    this.onContinueRequested,
    this.onJumpHomeRequested,
  });

  @override
  State<ArchivesScreen> createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<ArchivesScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  String? _error;
  List<ReplyThreadSummary> _threads = <ReplyThreadSummary>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppStateScope.of(context).isLoggedIn && _threads.isEmpty && !_isLoading) {
      _loadThreads();
    }
  }

  Future<void> _loadThreads() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final threads = await _api.getReplyThreads();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load archives.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(ReplyThreadSummary thread) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ArchiveDetailScreen(
          threadId: thread.id,
          summary: thread,
          onContinueRequested: widget.onContinueRequested,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      await _loadThreads();
    }
  }

  Future<bool> _confirmDelete(ReplyThreadSummary thread) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Archive'),
          content: Text('Delete "${thread.title}" from your archives?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return false;

    try {
      await _api.deleteReplyThread(thread.id);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete archived conversation.')),
      );
      return false;
    }
  }

  Future<void> _navigateToLogin() async {
    final didLogin = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    if (didLogin == true) {
      await AppStateScope.of(context).reloadFromStorage();
      if (!mounted) return;
      await _loadThreads();
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final days = now.difference(local).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${local.month}/${local.day}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    if (!appState.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 38, color: colorScheme.secondary),
              const SizedBox(height: 10),
              Text(
                'Sign in to access Archives.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved reply threads live in your account.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _navigateToLogin,
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 30),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadThreads,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Your archives are empty.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a screenshot and generate a reply to save your first archived conversation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: widget.onJumpHomeRequested,
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return Dismissible(
            key: ValueKey('archive-${thread.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            confirmDismiss: (_) => _confirmDelete(thread),
            onDismissed: (_) {
              setState(() {
                _threads = _threads.where((t) => t.id != thread.id).toList();
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await _openDetail(thread);
                },
                child: Ink(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.surfaceContainerHighest,
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: thread.thumbnailUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    thread.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Icon(
                                        Icons.chat_bubble_outline,
                                        color: colorScheme.onSurfaceVariant,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.chat_bubble_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      thread.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(thread.updatedAt),
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                thread.snippet.isEmpty
                                    ? 'No snippet available.'
                                    : thread.snippet,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Reply',
                                      style: Theme.of(context).textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${thread.replyCount} saved',
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const Spacer(),
                                  if (thread.isLocked)
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16,
                                      color: colorScheme.secondary,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
