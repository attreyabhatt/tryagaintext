class CommunityAuthor {
  final int? id;
  final String username;
  final bool isPro;

  const CommunityAuthor({this.id, required this.username, required this.isPro});

  factory CommunityAuthor.fromJson(Map<String, dynamic> j) {
    return CommunityAuthor(
      id: j['id'] as int?,
      username: j['username'] as String? ?? 'Unknown',
      isPro: j['is_pro'] as bool? ?? false,
    );
  }

  String get displayName {
    final value = username.trim();
    if (value.isEmpty) return 'Unknown';
    final atIndex = value.indexOf('@');
    if (atIndex > 0) {
      return value.substring(0, atIndex);
    }
    return value;
  }
}

class CommunityComment {
  final int id;
  final CommunityAuthor author;
  final String body;
  int likeCount;
  bool userLiked;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.author,
    required this.body,
    required this.likeCount,
    required this.userLiked,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> j) {
    return CommunityComment(
      id: j['id'] as int,
      author: CommunityAuthor.fromJson(
        j['author'] as Map<String, dynamic>? ?? {},
      ),
      body: j['body'] as String? ?? '',
      likeCount: j['like_count'] as int? ?? 0,
      userLiked: j['user_liked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityPoll {
  final int sendItCount;
  final int dontSendItCount;
  final String? userVote;

  const CommunityPoll({
    required this.sendItCount,
    required this.dontSendItCount,
    this.userVote,
  });

  factory CommunityPoll.fromJson(Map<String, dynamic> j) {
    return CommunityPoll(
      sendItCount: j['send_it_count'] as int? ?? 0,
      dontSendItCount: j['dont_send_it_count'] as int? ?? 0,
      userVote: j['user_vote'] as String?,
    );
  }

  CommunityPoll copyWith({
    int? sendItCount,
    int? dontSendItCount,
    String? userVote,
    bool clearUserVote = false,
  }) {
    return CommunityPoll(
      sendItCount: sendItCount ?? this.sendItCount,
      dontSendItCount: dontSendItCount ?? this.dontSendItCount,
      userVote: clearUserVote ? null : (userVote ?? this.userVote),
    );
  }
}

class CommunityPost {
  final int id;
  final String title;
  final String bodyPreview;
  final String? body;
  final String category;
  final CommunityAuthor author;
  final int voteScore;
  final int commentCount;
  final String? imageUrl;
  final bool isFeatured;
  final bool isTrending;
  final bool isNew;
  final String? userVote;
  final bool isAnonymous;
  final CommunityPoll? poll;
  final DateTime createdAt;
  final List<CommunityComment> comments;

  const CommunityPost({
    required this.id,
    required this.title,
    required this.bodyPreview,
    this.body,
    required this.category,
    required this.author,
    required this.voteScore,
    required this.commentCount,
    this.imageUrl,
    required this.isFeatured,
    required this.isTrending,
    required this.isNew,
    this.userVote,
    this.isAnonymous = false,
    this.poll,
    required this.createdAt,
    this.comments = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) {
    return CommunityPost(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      bodyPreview: j['body_preview'] as String? ?? '',
      body: j['body'] as String?,
      category: j['category'] as String? ?? '',
      author: CommunityAuthor.fromJson(
        j['author'] as Map<String, dynamic>? ?? {},
      ),
      voteScore: j['vote_score'] as int? ?? 0,
      commentCount: j['comment_count'] as int? ?? 0,
      imageUrl: j['image_url'] as String?,
      isFeatured: j['is_featured'] as bool? ?? false,
      isTrending: j['is_trending'] as bool? ?? false,
      isNew: j['is_new'] as bool? ?? false,
      userVote: j['user_vote'] as String?,
      isAnonymous: j['is_anonymous'] as bool? ?? false,
      poll: j['poll'] != null
          ? CommunityPoll.fromJson(j['poll'] as Map<String, dynamic>)
          : null,
      createdAt:
          DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      comments:
          (j['comments'] as List<dynamic>?)
              ?.map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  CommunityPost copyWith({
    int? voteScore,
    String? userVote,
    bool clearUserVote = false,
    List<CommunityComment>? comments,
    int? commentCount,
    CommunityPoll? poll,
    bool clearPoll = false,
  }) {
    return CommunityPost(
      id: id,
      title: title,
      bodyPreview: bodyPreview,
      body: body,
      category: category,
      author: author,
      voteScore: voteScore ?? this.voteScore,
      commentCount: commentCount ?? this.commentCount,
      imageUrl: imageUrl,
      isFeatured: isFeatured,
      isTrending: isTrending,
      isNew: isNew,
      userVote: clearUserVote ? null : (userVote ?? this.userVote),
      isAnonymous: isAnonymous,
      poll: clearPoll ? null : (poll ?? this.poll),
      createdAt: createdAt,
      comments: comments ?? this.comments,
    );
  }

  String get displayAuthorName =>
      isAnonymous ? 'Anonymous' : author.displayName;

  String get displayAuthorInitial {
    final value = displayAuthorName.trim();
    if (value.isEmpty) return '?';
    return value[0].toUpperCase();
  }

  bool get showAuthorProBadge => !isAnonymous && author.isPro;
}

class CommunityFeedResponse {
  final List<CommunityPost> posts;
  final int page;
  final bool hasMore;

  const CommunityFeedResponse({
    required this.posts,
    required this.page,
    required this.hasMore,
  });

  factory CommunityFeedResponse.fromJson(Map<String, dynamic> j) {
    return CommunityFeedResponse(
      posts:
          (j['posts'] as List<dynamic>?)
              ?.map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      page: j['page'] as int? ?? 1,
      hasMore: j['has_more'] as bool? ?? false,
    );
  }
}
