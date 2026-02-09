class QueryHistoryItem {
  final int id;
  final String question;
  final String answer;
  final double confidence;
  final DateTime createdAt;
  final int courseId;
  final String courseTitle;
  final List<Map<String, dynamic>> sources;

  QueryHistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.confidence,
    required this.createdAt,
    required this.courseId,
    required this.courseTitle,
    required this.sources,
  });

  factory QueryHistoryItem.fromJson(Map<String, dynamic> json) {
    return QueryHistoryItem(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      courseId: json['course_id'] ?? 0,
      courseTitle: json['course_title'] ?? 'Unknown Course',
      sources: json['sources'] is List
          ? List<Map<String, dynamic>>.from(json['sources'] as List)
          : [],
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
