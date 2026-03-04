import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/community_post.dart';
import '../../services/api_client.dart';
import '../../services/community_guidelines_service.dart';
import '../widgets/content_action_sheet.dart';
import '../../state/app_state.dart';
import '../widgets/community_poll_widget.dart';
import '../widgets/community_post_card.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final _api = ApiClient();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentFocusNode = FocusNode();

  late CommunityPost _post;
  bool _isLoadingDetail = true;
  bool _isSubmittingComment = false;
  bool _isVoting = false;
  bool _hasCommentText = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _commentController.addListener(_onCommentTextChanged);
    _loadDetail();
  }

  void _onCommentTextChanged() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText != _hasCommentText) {
      setState(() => _hasCommentText = hasText);
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentTextChanged);
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _api.getCommunityPostDetail(_post.id);
      if (mounted) {
        setState(() {
          _post = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _vote(String voteType) async {
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to vote.')));
      return;
    }
    if (_isVoting) return;
    HapticFeedback.selectionClick();
    setState(() => _isVoting = true);

    try {
      final result = await _api.voteCommunityPost(_post.id, voteType);
      if (mounted) {
        setState(() {
          _post = _post.copyWith(
            voteScore: result['vote_score'] as int? ?? _post.voteScore,
            userVote: result['user_vote'] as String?,
            clearUserVote: result['user_vote'] == null,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  Future<void> _submitComment() async {
    if (_isSubmittingComment) return;
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to comment.')));
      return;
    }

    // EULA gate — first-time commenting requires acceptance
    final accepted = await CommunityGuidelinesService.ensureAccepted(context);
    if (!accepted || !mounted) return;

    setState(() => _isSubmittingComment = true);
    try {
      final comment = await _api.addCommunityComment(_post.id, body);
      if (mounted) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        HapticFeedback.lightImpact();
        final updatedComments = [..._post.comments, comment];
        setState(() {
          _post = _post.copyWith(
            comments: updatedComments,
            commentCount: updatedComments.length,
          );
        });
        // Scroll to bottom to show new comment
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _toggleLike(CommunityComment comment) async {
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like comments.')),
      );
      return;
    }
    HapticFeedback.selectionClick();

    // Optimistic update
    setState(() {
      comment.userLiked = !comment.userLiked;
      comment.likeCount += comment.userLiked ? 1 : -1;
    });

    try {
      final result = await _api.likeCommunityComment(comment.id);
      if (mounted) {
        setState(() {
          comment.likeCount = result['like_count'] as int? ?? comment.likeCount;
          comment.userLiked = result['liked'] as bool? ?? comment.userLiked;
        });
      }
    } catch (_) {
      // Revert optimistic update
      if (mounted) {
        setState(() {
          comment.userLiked = !comment.userLiked;
          comment.likeCount += comment.userLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteCommunityComment(comment.id);
      if (mounted) {
        final updated = _post.comments
            .where((c) => c.id != comment.id)
            .toList();
        setState(() {
          _post = _post.copyWith(
            comments: updated,
            commentCount: updated.length,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showCommentActions(CommunityComment comment) async {
    final appState = AppStateScope.of(context);
    final isOwner = appState.isLoggedIn && appState.user?.username == comment.author.username;

    final action = await showContentActionSheet(
      context,
      contentType: 'comment',
      contentId: comment.id,
      author: comment.author,
      isOwner: isOwner,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.delete:
        await _deleteComment(comment);
      case ContentAction.report:
        if (mounted) {
          await showReportReasonSheet(context, contentType: 'comment', contentId: comment.id);
        }
      case ContentAction.block:
        if (mounted) {
          final blocked = await handleBlockUser(context, author: comment.author);
          if (blocked && mounted) {
            // Remove blocked user's comments from view
            final updated = _post.comments
                .where((c) => c.author.username != comment.author.username)
                .toList();
            setState(() {
              _post = _post.copyWith(comments: updated, commentCount: updated.length);
            });
          }
        }
    }
  }

  Future<void> _votePoll(String choice) async {
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to vote.')),
      );
      return;
    }
    try {
      final result = await _api.votePoll(_post.id, choice);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(
          poll: CommunityPoll(
            sendItCount: result['send_it_count'] as int? ?? 0,
            dontSendItCount: result['dont_send_it_count'] as int? ?? 0,
            userVote: result['user_vote'] as String?,
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showPostActions(bool isOwner) async {
    final action = await showContentActionSheet(
      context,
      contentType: 'post',
      contentId: _post.id,
      author: _post.author,
      isOwner: isOwner,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.delete:
        await _deletePost();
      case ContentAction.report:
        if (mounted) {
          await showReportReasonSheet(context, contentType: 'post', contentId: _post.id);
        }
      case ContentAction.block:
        if (mounted) {
          final blocked = await handleBlockUser(context, author: _post.author);
          if (blocked && mounted) Navigator.pop(context);
        }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteCommunityPost(_post.id);
      if (mounted) Navigator.pop(context, _post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final appState = AppStateScope.of(context);
    final isOwner =
        appState.isLoggedIn && appState.user?.username == _post.author.username;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Discussion',
          style: tt.headlineSmall?.copyWith(fontSize: 20, color: cs.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostActions(isOwner),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingDetail
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : _buildContent(cs, tt, appState),
          ),
          _buildCommentInput(cs, appState),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, TextTheme tt, AppState appState) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Post card (full body)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.secondary.withValues(alpha: 0.12),
                    child: Text(
                      _post.author.displayName.isNotEmpty
                          ? _post.author.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _post.author.displayName,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_post.author.isPro) ...[
                            const SizedBox(width: 6),
                            _ProBadge(cs: cs),
                          ],
                        ],
                      ),
                      Text(
                        '${timeAgoFromDate(_post.createdAt)} · ${_categoryLabel(_post.category)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title (Playfair Display — editorial)
              Text(
                _post.title,
                style: tt.headlineSmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 10),

              // Full body
              Text(
                _post.body ?? _post.bodyPreview,
                style: tt.bodyMedium?.copyWith(
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              ),

              // Poll
              if (_post.poll != null) ...[
                const SizedBox(height: 14),
                CommunityPollWidget(
                  poll: _post.poll!,
                  onVote: (choice) => _votePoll(choice),
                ),
              ],

              // Image
              if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Image.network(
                      _post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: cs.surfaceContainerHigh,
                          highlightColor: cs.surfaceContainerHighest,
                          child: Container(height: 200, width: double.infinity, color: cs.surfaceContainerHigh),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        width: double.infinity,
                        color: cs.surfaceContainerHigh,
                        child: Icon(Icons.image_not_supported_outlined, color: cs.onSurfaceVariant, size: 32),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 4),

              // Vote row
              Row(
                children: [
                  _VoteButton(
                    icon: Icons.arrow_upward_rounded,
                    active: _post.userVote == 'up',
                    activeColor: cs.primary,
                    onTap: () => _vote('up'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_post.voteScore}',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _post.userVote != null
                            ? cs.primary
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  _VoteButton(
                    icon: Icons.arrow_downward_rounded,
                    active: _post.userVote == 'down',
                    activeColor: cs.error,
                    onTap: () => _vote('down'),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_post.commentCount}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Comments header
        if (_post.comments.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Comments (${_post.commentCount})',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 4),
        ],

        // Comments list
        ..._post.comments.map(
          (comment) => _CommentTile(
            comment: comment,
            currentUsername: appState.user?.username,
            postAuthorUsername: _post.author.username,
            isPostAnonymous: _post.isAnonymous,
            onLike: () => _toggleLike(comment),
            onDelete: () => _deleteComment(comment),
            onMoreTap: () => _showCommentActions(comment),
          ),
        ),

        if (_post.comments.isEmpty && !_isLoadingDetail)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No comments yet',
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start the conversation!',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentInput(ColorScheme cs, AppState appState) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final userInitial = appState.isLoggedIn && appState.user != null
        ? (appState.user!.username.isNotEmpty
              ? appState.user!.username[0].toUpperCase()
              : '?')
        : '?';

    return Container(
      color: cs.surface,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: isLight
                ? cs.surfaceContainerHighest
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: isLight
                ? Border.all(color: cs.outlineVariant, width: 0.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.12),
                blurRadius: isLight ? 8 : 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 8, right: 6, top: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Gold avatar with Playfair initial — anchored to bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.secondary,
                  child: Text(
                    userInitial,
                    style: GoogleFonts.playfairDisplay(
                      color: cs.surface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Expandable text input with generous padding
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: appState.isLoggedIn
                        ? 'Add a comment...'
                        : 'Sign in to comment',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    isDense: false,
                  ),
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                  enabled: appState.isLoggedIn,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 4),
              // State-based send button — anchored to bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : GestureDetector(
                        onTap: _hasCommentText ? _submitComment : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hasCommentText
                                ? cs.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: _hasCommentText
                                ? cs.onPrimary
                                : cs.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    return switch (cat) {
      'success_story' => 'Success Stories',
      'opening_line' => 'Opening Lines',
      'dating_advice' => 'Dating Advice',
      'app_feedback' => 'App Feedback',
      _ => cat,
    };
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? activeColor : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  final ColorScheme cs;
  const _ProBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: cs.secondary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final String? currentUsername;
  final String? postAuthorUsername;
  final bool isPostAnonymous;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback? onMoreTap;

  const _CommentTile({
    required this.comment,
    required this.currentUsername,
    this.postAuthorUsername,
    this.isPostAnonymous = false,
    required this.onLike,
    required this.onDelete,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isOwner = currentUsername == comment.author.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.secondary.withValues(alpha: 0.12),
            child: Text(
              comment.author.displayName.isNotEmpty
                  ? comment.author.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.displayName,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (comment.author.isPro) ...[
                      const SizedBox(width: 6),
                      _ProBadge(cs: cs),
                    ],
                    if (!isPostAnonymous &&
                        postAuthorUsername != null &&
                        comment.author.username == postAuthorUsername) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OP',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      timeAgoFromDate(comment.createdAt),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (onMoreTap != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onMoreTap,
                        child: Icon(Icons.more_vert, size: 16, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.body, style: tt.bodyMedium?.copyWith(height: 1.4)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            comment.userLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: comment.userLiked
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likeCount}',
                            style: tt.bodySmall?.copyWith(
                              color: comment.userLiked
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onDelete,
                        child: Text(
                          'Delete',
                          style: tt.bodySmall?.copyWith(color: cs.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
