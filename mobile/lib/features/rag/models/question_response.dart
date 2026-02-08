class QuestionResponse {
  final String answer;
  final double confidence;
  final List<Map<String, dynamic>> sources;
  final int responseTimeMs;

  QuestionResponse({
    required this.answer,
    required this.confidence,
    required this.sources,
    required this.responseTimeMs,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []),
      responseTimeMs: json['response_time_ms'] ?? 0,
    );
  }
}
