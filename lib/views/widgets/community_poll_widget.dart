import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/community_post.dart';

/// Displays a "Send it / Don't send it" poll with vote counts and progress bars.
///
/// [onVote] is called when the user taps a choice. Pass null to show read-only
/// results (e.g. for unauthenticated users — the caller can show a snackbar).
class CommunityPollWidget extends StatelessWidget {
  final CommunityPoll poll;
  final ValueChanged<String>? onVote;
  final bool compact;

  const CommunityPollWidget({
    super.key,
    required this.poll,
    this.onVote,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = poll.sendItCount + poll.dontSendItCount;
    final sendPct = total > 0 ? poll.sendItCount / total : 0.0;
    final dontPct = total > 0 ? poll.dontSendItCount / total : 0.0;

    return GestureDetector(
      // Absorb taps so they don't propagate to parent card onTap
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PollOption(
            label: 'Send it',
            icon: Icons.send_rounded,
            count: poll.sendItCount,
            percentage: sendPct,
            isSelected: poll.userVote == 'send_it',
            hasVoted: poll.userVote != null,
            cs: cs,
            tt: tt,
            compact: compact,
            onTap: onVote != null ? () {
              HapticFeedback.lightImpact();
              onVote!('send_it');
            } : null,
          ),
          SizedBox(height: compact ? 6 : 8),
          _PollOption(
            label: "Don't send it",
            icon: Icons.block_rounded,
            count: poll.dontSendItCount,
            percentage: dontPct,
            isSelected: poll.userVote == 'dont_send_it',
            hasVoted: poll.userVote != null,
            cs: cs,
            tt: tt,
            compact: compact,
            onTap: onVote != null ? () {
              HapticFeedback.lightImpact();
              onVote!('dont_send_it');
            } : null,
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            '$total vote${total == 1 ? '' : 's'}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final double percentage;
  final bool isSelected;
  final bool hasVoted;
  final ColorScheme cs;
  final TextTheme tt;
  final bool compact;
  final VoidCallback? onTap;

  const _PollOption({
    required this.label,
    required this.icon,
    required this.count,
    required this.percentage,
    required this.isSelected,
    required this.hasVoted,
    required this.cs,
    required this.tt,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 42.0;
    final fontSize = compact ? 12.0 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Progress bar background
            if (hasVoted)
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                ),
              ),
            // Label + count
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: compact ? 14 : 16,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: tt.bodySmall?.copyWith(
                        fontSize: fontSize,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (hasVoted)
                      Text(
                        '${(percentage * 100).round()}%',
                        style: tt.bodySmall?.copyWith(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
