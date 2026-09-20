class ReplyThreadPreview {
  final String message;
  final double? confidenceScore;
  final String? whyItWorks;

  const ReplyThreadPreview({
    required this.message,
    this.confidenceScore,
    this.whyItWorks,
  });

  factory ReplyThreadPreview.fromJson(Map<String, dynamic> json) {
    final confidence = json['confidence_score'];
    return ReplyThreadPreview(
      message: (json['message'] as String? ?? '').trim(),
      confidenceScore: confidence is num ? confidence.toDouble() : null,
      whyItWorks: (json['why_it_works'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (whyItWorks != null && whyItWorks!.isNotEmpty)
        'why_it_works': whyItWorks,
    };
  }
}

class ReplyThreadSummary {
  final int id;
  final String title;
  final String snippet;
  final DateTime updatedAt;
  final DateTime createdAt;
  final int replyCount;
  final bool isLocked;
  final String? thumbnailUrl;

  const ReplyThreadSummary({
    required this.id,
    required this.title,
    required this.snippet,
    required this.updatedAt,
    required this.createdAt,
    required this.replyCount,
    required this.isLocked,
    this.thumbnailUrl,
  });

  factory ReplyThreadSummary.fromJson(Map<String, dynamic> json) {
    return ReplyThreadSummary(
      id: json['id'] as int,
      title: (json['title'] as String? ?? '').trim(),
      snippet: (json['snippet'] as String? ?? '').trim(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      replyCount: json['reply_count'] as int? ?? 0,
      isLocked: json['is_locked'] == true,
      thumbnailUrl:
          (json['thumbnail_url'] as String?)?.trim().isNotEmpty == true
          ? (json['thumbnail_url'] as String).trim()
          : null,
    );
  }
}

class ReplyThreadDetail {
  final int id;
  final String title;
  final String stitchedTranscript;
  final List<ReplyThreadPreview> latestReplies;
  final bool isLocked;
  final String? thumbnailUrl;
  final int? latestGenerationEventId;
  final DateTime updatedAt;
  final DateTime createdAt;

  const ReplyThreadDetail({
    required this.id,
    required this.title,
    required this.stitchedTranscript,
    required this.latestReplies,
    required this.isLocked,
    required this.updatedAt,
    required this.createdAt,
    this.thumbnailUrl,
    this.latestGenerationEventId,
  });

  factory ReplyThreadDetail.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['latest_replies'];
    final replies = <ReplyThreadPreview>[];
    if (repliesRaw is List) {
      for (final item in repliesRaw) {
        if (item is Map<String, dynamic>) {
          replies.add(ReplyThreadPreview.fromJson(item));
        } else if (item is Map) {
          replies.add(
            ReplyThreadPreview.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    return ReplyThreadDetail(
      id: json['id'] as int,
      title: (json['title'] as String? ?? '').trim(),
      stitchedTranscript: (json['stitched_transcript'] as String? ?? '').trim(),
      latestReplies: replies,
      isLocked: json['is_locked'] == true,
      thumbnailUrl:
          (json['thumbnail_url'] as String?)?.trim().isNotEmpty == true
          ? (json['thumbnail_url'] as String).trim()
          : null,
      latestGenerationEventId: json['latest_generation_event_id'] as int?,
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ArchiveContinueRequest {
  final int threadId;
  final String conversationText;
  final bool autoGenerate;

  const ArchiveContinueRequest({
    required this.threadId,
    required this.conversationText,
    this.autoGenerate = false,
  });
}
