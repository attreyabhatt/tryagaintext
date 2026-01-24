class Suggestion {
  final String message;
  final double confidence;
  final String? whyItWorks;
  final String? imageUrl;

  Suggestion({
    required this.message,
    required this.confidence,
    this.whyItWorks,
    this.imageUrl,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) {
    return Suggestion(
      message: j['message'] as String? ?? '',
      confidence: (j['confidence_score'] as num?)?.toDouble() ?? 0.0,
      whyItWorks: j['why_it_works'] as String?,
      imageUrl: j['image_url'] as String?,
    );
  }
}
