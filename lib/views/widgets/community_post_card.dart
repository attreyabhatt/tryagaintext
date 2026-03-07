import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../l10n/l10n.dart';
import '../../models/community_post.dart';
import 'community_poll_widget.dart';

/// Reusable card for displaying a community post in the feed.
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final ValueChanged<String>? onPollVote;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onMoreTap,
    this.onPollVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    if (post.isFeatured) {
      return _buildFeaturedCard(context, cs, tt, isLight);
    }
    return _buildNormalCard(context, cs, tt, isLight);
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    bool isLight,
  ) {
    final displayAuthorName = post.isAnonymous ? context.l10n.communityAnonymous : post.author.displayName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    cs.secondaryContainer,
                    cs.secondaryContainer.withValues(alpha: 0.6),
                  ]
                : [
                    cs.secondary.withValues(alpha: 0.10),
                    cs.primary.withValues(alpha: 0.06),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.secondary.withValues(alpha: isLight ? 0.2 : 0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FEATURED badge + author + time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.communityFeaturedBadge,
                            style: TextStyle(
                              color: cs.onSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$displayAuthorName · ${_timeAgo(context, post.createdAt)} · ${_categoryLabel(context, post.category)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onMoreTap != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onMoreTap,
                            child: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title (Playfair Display editorial)
                    Text(
                      post.title,
                      style: tt.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Body preview
                    Text(
                      post.bodyPreview,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Poll
                    if (post.poll != null) ...[
                      const SizedBox(height: 10),
                      CommunityPollWidget(
                        poll: post.poll!,
                        onVote: onPollVote,
                        compact: true,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Footer: hearts + comments
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: cs.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(post.voteScore),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.chat_bubble,
                          size: 13,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(post.commentCount),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: small image thumbnail (if available)
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    post.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: cs.surfaceContainerHigh,
                        highlightColor: cs.surfaceContainerHighest,
                        child: Container(
                          width: 80,
                          height: 80,
                          color: cs.surfaceContainerHigh,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: cs.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    bool isLight,
  ) {
    final displayAuthorName = post.isAnonymous ? context.l10n.communityAnonymous : post.author.displayName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isLight ? cs.surface : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLight
                ? cs.outlineVariant
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: isLight ? 0.8 : 0.5,
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row + badge row
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.secondary.withValues(alpha: 0.12),
                    child: Text(
                      post.displayAuthorInitial,
                      style: TextStyle(
                        color: cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayAuthorName,
                              style: tt.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            if (post.showAuthorProBadge) ...[
                              const SizedBox(width: 6),
                              _Badge(
                                label: context.l10n.communityProBadge,
                                bg: cs.secondary.withValues(alpha: 0.2),
                                fg: cs.secondary,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${_timeAgo(context, post.createdAt)} · ${_categoryLabel(context, post.category)}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  Row(
                    children: [
                      if (post.isTrending)
                        _Badge(
                          label: context.l10n.communityTrendingBadge,
                          bg: cs.primary.withValues(alpha: 0.15),
                          fg: cs.primary,
                        ),
                      if (post.isNew && !post.isTrending)
                        _Badge(
                          label: context.l10n.communityNewBadge,
                          bg: cs.surfaceContainerHighest,
                          fg: cs.onSurface,
                        ),
                      if (onMoreTap != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onMoreTap,
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title (Playfair Display editorial)
              Text(
                post.title,
                style: tt.headlineSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Body preview
              Text(
                post.bodyPreview,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Poll
              if (post.poll != null) ...[
                const SizedBox(height: 10),
                CommunityPollWidget(
                  poll: post.poll!,
                  onVote: onPollVote,
                  compact: true,
                ),
              ],

              // Image thumbnail
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    post.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: cs.surfaceContainerHigh,
                        highlightColor: cs.surfaceContainerHighest,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          color: cs.surfaceContainerHigh,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: double.infinity,
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: cs.onSurfaceVariant,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Footer: votes + comments
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.voteScore}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000) {
    final k = count / 1000;
    return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
  }
  return '$count';
}

String _categoryLabel(BuildContext context, String cat) {
  final l10n = context.l10n;
  return switch (cat) {
    'help_me_reply' => l10n.communityCategoryHelpMeReply,
    'dating_advice' => l10n.communityCategoryDatingAdvice,
    'rate_my_profile' => l10n.communityCategoryRateMyProfile,
    'wins' => l10n.communityCategoryWins,
    _ => cat,
  };
}

String timeAgoFromDate(BuildContext context, DateTime date) => _timeAgo(context, date);

String _timeAgo(BuildContext context, DateTime date) {
  final l10n = context.l10n;
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return l10n.communityTimeJustNow;
  if (diff.inMinutes < 60) return l10n.communityTimeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.communityTimeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.communityTimeDaysAgo(diff.inDays);
  return l10n.communityTimeWeeksAgo((diff.inDays / 7).floor());
}
