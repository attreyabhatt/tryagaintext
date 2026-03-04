import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/community_post.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import '../widgets/community_post_card.dart';
import '../widgets/content_action_sheet.dart';
import 'community_post_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _api = ApiClient();
  final _scrollController = ScrollController();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _selectedCategory; // null = All
  String _sort = 'hot';
  String? _error;

  static const _categories = [
    (value: null, label: 'All'),
    (value: 'help_me_reply', label: 'Help Me Reply 🚨'),
    (value: 'rate_my_profile', label: 'Rate My Profile 📸'),
    (value: 'wins', label: 'Wins 🏆'),
  ];

  List<CommunityPost> _featuredFirst(Iterable<CommunityPost> posts) {
    final seenIds = <int>{};
    final featured = <CommunityPost>[];
    final regular = <CommunityPost>[];
    for (final post in posts) {
      if (!seenIds.add(post.id)) continue;
      if (post.isFeatured) {
        featured.add(post);
      } else {
        regular.add(post);
      }
    }
    return [...featured, ...regular];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _posts = [];
        _page = 1;
        _hasMore = true;
      }
    });

    try {
      final result = await _api.getCommunityPosts(
        category: _selectedCategory,
        sort: _sort,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _posts = _featuredFirst(result.posts);
          _page = 1;
          _hasMore = result.hasMore;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _api.getCommunityPosts(
        category: _selectedCategory,
        sort: _sort,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _posts = _featuredFirst([..._posts, ...result.posts]);
          _page++;
          _hasMore = result.hasMore;
        });
      }
    } catch (_) {
      // Silently fail on pagination
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPost(CommunityPost post) async {
    final deletedPostId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => CommunityPostDetailScreen(post: post)),
    );
    if (deletedPostId != null && mounted) {
      setState(() {
        _posts = _posts.where((p) => p.id != deletedPostId).toList();
      });
    }
  }

  Future<void> _openCreatePost() async {
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a post.')),
      );
      return;
    }
    HapticFeedback.lightImpact();
    final newPost = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (newPost != null && mounted) {
      setState(() => _posts = _featuredFirst([newPost, ..._posts]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Community',
          style: tt.headlineSmall?.copyWith(
            fontSize: 20,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_outlined),
            tooltip: 'Sort',
            onPressed: _showSortSheet,
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              cs.primary.withValues(alpha: isLight ? 0.85 : 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: isLight ? 0.2 : 0.4),
              blurRadius: isLight ? 12 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openCreatePost,
          backgroundColor: Colors.transparent,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          child: const Icon(Icons.edit_outlined),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.white, Colors.transparent],
              stops: const [0.0, 0.85, 0.92, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat.value;
                  return FilterChip(
                    label: Text(cat.label),
                    selected: selected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.value);
                      _loadPosts(refresh: true);
                    },
                    showCheckmark: false,
                    selectedColor: cs.secondary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? cs.secondary : cs.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: selected
                        ? BorderSide(color: cs.secondary.withValues(alpha: 0.3))
                        : BorderSide.none,
                    backgroundColor: cs.surfaceContainerHighest,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                  );
                },
              ),
            ),
          ),

          // Post list
          Expanded(child: _buildBody(cs, tt)),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_outlined,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load posts.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => _loadPosts(refresh: true),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 80,
                color: cs.onSurfaceVariant.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 12),
              Text(
                'No posts yet',
                style: tt.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Be the first to share something!',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final appState = AppStateScope.of(context);
    final visiblePosts = _posts
        .where((p) => p.author.id == null || !appState.isUserBlocked(p.author.id!))
        .toList();

    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      color: cs.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: visiblePosts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == visiblePosts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = visiblePosts[i];
          return CommunityPostCard(
            post: post,
            onTap: () => _openPost(post),
            onMoreTap: () => _showPostActions(post),
            onPollVote: post.poll != null
                ? (choice) => _votePoll(post, choice)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _votePoll(CommunityPost post, String choice) async {
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to vote.')),
      );
      return;
    }
    try {
      final result = await _api.votePoll(post.id, choice);
      if (!mounted) return;
      final updatedPoll = CommunityPoll(
        sendItCount: result['send_it_count'] as int? ?? 0,
        dontSendItCount: result['dont_send_it_count'] as int? ?? 0,
        userVote: result['user_vote'] as String?,
      );
      setState(() {
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx != -1) {
          _posts[idx] = _posts[idx].copyWith(poll: updatedPoll);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showPostActions(CommunityPost post) async {
    final appState = AppStateScope.of(context);
    final isOwner = appState.isLoggedIn && appState.user?.username == post.author.username;

    final action = await showContentActionSheet(
      context,
      contentType: 'post',
      contentId: post.id,
      author: post.author,
      isOwner: isOwner,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.delete:
        try {
          await ApiClient().deleteCommunityPost(post.id);
          if (mounted) {
            setState(() => _posts.removeWhere((p) => p.id == post.id));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      case ContentAction.report:
        if (mounted) {
          await showReportReasonSheet(context, contentType: 'post', contentId: post.id);
        }
      case ContentAction.block:
        if (mounted) {
          await handleBlockUser(context, author: post.author);
          // Blocked users' posts are filtered reactively via visiblePosts
        }
    }
  }

  void _showSortSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
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
                  'Sort posts',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              for (final s in [
                ('hot', Icons.local_fire_department, 'Hot'),
                ('new', Icons.auto_awesome, 'New'),
                ('top', Icons.trending_up, 'Top'),
              ])
                ListTile(
                  dense: true,
                  leading: Icon(
                    s.$2,
                    color: _sort == s.$1 ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(
                    s.$3,
                    style: TextStyle(
                      color: _sort == s.$1 ? cs.primary : null,
                      fontWeight: _sort == s.$1 ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: _sort == s.$1
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (_sort != s.$1) {
                      setState(() => _sort = s.$1);
                      _loadPosts(refresh: true);
                    }
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
