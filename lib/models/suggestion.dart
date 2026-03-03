class Suggestion {
  final String message;
  final double confidence;
  final String? whyItWorks;
  final String? imageUrl;
  final int? generationEventId;
  // Blurred cliff fields
  final bool isLocked;
  final String? blurPreview;
  final int? lockedReplyId;

  Suggestion({
    required this.message,
    required this.confidence,
    this.whyItWorks,
    this.imageUrl,
    this.generationEventId,
    this.isLocked = false,
    this.blurPreview,
    this.lockedReplyId,
  });

  factory Suggestion.fromJson(
    Map<String, dynamic> j, {
    int? generationEventId,
  }) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    return Suggestion(
      message:
          (j['message'] as String?) ?? (j['blur_preview'] as String?) ?? '',
      confidence: (j['confidence_score'] as num?)?.toDouble() ?? 0.0,
      whyItWorks: j['why_it_works'] as String?,
      imageUrl: j['image_url'] as String?,
      generationEventId:
          generationEventId ?? parseInt(j['generation_event_id']),
      isLocked: parseBool(j['is_locked']),
      blurPreview: j['blur_preview'] as String?,
      lockedReplyId: parseInt(j['locked_reply_id']),
    );
  }
}
