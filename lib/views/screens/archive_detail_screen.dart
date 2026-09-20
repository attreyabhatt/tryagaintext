import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/reply_thread.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import 'pricing_screen.dart';

class ArchiveDetailScreen extends StatefulWidget {
  final int threadId;
  final ReplyThreadSummary? summary;
  final Future<void> Function(ArchiveContinueRequest request)? onContinueRequested;

  const ArchiveDetailScreen({
    super.key,
    required this.threadId,
    this.summary,
    this.onContinueRequested,
  });

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  final ApiClient _api = ApiClient();
  ReplyThreadDetail? _detail;
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  bool _locked = false;
  String? _lockedMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _locked = false;
      _lockedMessage = null;
    });
    try {
      final detail = await _api.getReplyThreadDetail(widget.threadId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.insufficientCredits) {
        setState(() {
          _locked = true;
          _lockedMessage = e.message;
          _loading = false;
        });
      } else {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load archived conversation.';
        _loading = false;
      });
    }
  }

  Future<void> _deleteThread() async {
    if (_deleting) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Archive'),
          content: const Text(
            'This will permanently remove this archived conversation.',
          ),
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
    if (shouldDelete != true) return;

    setState(() => _deleting = true);
    try {
      await _api.deleteReplyThread(widget.threadId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _deleting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete archived conversation.')),
      );
      setState(() => _deleting = false);
    }
  }

  Future<void> _copyReply(ReplyThreadPreview reply) async {
    await Clipboard.setData(ClipboardData(text: reply.message));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _continueToHome({required bool autoGenerate}) async {
    final detail = _detail;
    if (detail == null) return;
    if (widget.onContinueRequested != null) {
      await widget.onContinueRequested!(
        ArchiveContinueRequest(
          threadId: detail.id,
          conversationText: detail.stitchedTranscript,
          autoGenerate: autoGenerate,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _detail?.title ?? widget.summary?.title ?? 'Archives';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _deleting ? null : _deleteThread,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _locked
          ? _buildLockedState(colorScheme)
          : _buildContent(colorScheme),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Unable to load archives.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: colorScheme.secondary,
                ),
                const SizedBox(height: 10),
                Text(
                  'This archive is locked.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _lockedMessage ??
                      'Upgrade to unlock older archives and continue this thread.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PricingScreen(),
                      ),
                    );
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final detail = _detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    final appState = AppStateScope.of(context);
    final canRegenerate = !detail.isLocked;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  detail.stitchedTranscript,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Latest Replies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...detail.latestReplies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _copyReply(reply),
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _continueToHome(autoGenerate: false),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Continue'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: canRegenerate
                ? () => _continueToHome(autoGenerate: true)
                : null,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(appState.isSubscribed ? 'Regenerate' : 'Regenerate'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
