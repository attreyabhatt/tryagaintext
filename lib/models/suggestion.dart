class Suggestion {
  final String message;
  final double confidence;

  Suggestion({required this.message, required this.confidence});

  factory Suggestion.fromJson(Map<String, dynamic> j) {
    return Suggestion(
      message: j['message'] as String? ?? '',
      confidence: (j['confidence_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
