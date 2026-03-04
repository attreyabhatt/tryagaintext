import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/community_post.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';

/// Shows a bottom sheet with Report/Block options (for other users' content)
/// or Delete option (for own content).
Future<ContentAction?> showContentActionSheet(
  BuildContext context, {
  required String contentType, // 'post' or 'comment'
  required int contentId,
  required CommunityAuthor author,
  required bool isOwner,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<ContentAction>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final tt = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isOwner) ...[
              ListTile(
                leading: Icon(Icons.delete_outline, color: cs.error),
                title: Text('Delete', style: tt.bodyLarge?.copyWith(color: cs.error)),
                onTap: () => Navigator.pop(ctx, ContentAction.delete),
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.flag_outlined, color: cs.onSurface),
                title: Text('Report Content', style: tt.bodyLarge),
                onTap: () => Navigator.pop(ctx, ContentAction.report),
              ),
              // Only show block if author has an ID (not anonymous/deleted)
              if (author.id != null) ...[
                ListTile(
                  leading: Icon(Icons.block, color: cs.error),
                  title: Text('Block User', style: tt.bodyLarge?.copyWith(color: cs.error)),
                  subtitle: Text(
                    'Hide all content from ${author.displayName}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  onTap: () => Navigator.pop(ctx, ContentAction.block),
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Shows the report reason picker and submits the report.
Future<void> showReportReasonSheet(
  BuildContext context, {
  required String contentType,
  required int contentId,
}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final tt = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Why are you reporting this?',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in _reportReasons)
              ListTile(
                leading: Icon(entry.icon, color: cs.onSurfaceVariant),
                title: Text(entry.label, style: tt.bodyLarge),
                onTap: () => Navigator.pop(ctx, entry.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (reason == null || !context.mounted) return;

  try {
    await ApiClient().reportCommunityContent(
      contentType: contentType,
      objectId: contentId,
      reason: reason,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Failed to report.')),
      );
    }
  }
}

/// Handles the block user flow with confirmation dialog.
Future<bool> handleBlockUser(
  BuildContext context, {
  required CommunityAuthor author,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Block User'),
      content: Text(
        'You will no longer see posts or comments from ${author.displayName}. You can unblock them later from your settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    final appState = AppStateScope.of(context);
    final blocked = await appState.toggleBlockUser(author.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            blocked
                ? '${author.displayName} has been blocked.'
                : '${author.displayName} has been unblocked.',
          ),
        ),
      );
    }
    return blocked;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to block user.')),
      );
    }
    return false;
  }
}

enum ContentAction { delete, report, block }

class _ReportReason {
  final String value;
  final String label;
  final IconData icon;
  const _ReportReason(this.value, this.label, this.icon);
}

const _reportReasons = [
  _ReportReason('spam', 'Spam', Icons.report_gmailerrorred_outlined),
  _ReportReason('harassment', 'Harassment', Icons.warning_amber_outlined),
  _ReportReason('inappropriate', 'Inappropriate Content', Icons.visibility_off_outlined),
  _ReportReason('other', 'Other', Icons.more_horiz),
];
