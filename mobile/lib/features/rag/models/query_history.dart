class ThreadSummary {
  final String threadId;
  final int courseId;
  final String title;
  final String lastQuestion;
  final String lastAnswer;
  final DateTime updatedAt;

  ThreadSummary({
    required this.threadId,
    required this.courseId,
    required this.title,
    required this.lastQuestion,
    required this.lastAnswer,
    required this.updatedAt,
  });

  factory ThreadSummary.fromJson(Map<String, dynamic> json) {
    return ThreadSummary(
      threadId: json['thread_id'] ?? '',
      courseId: json['course_id'] ?? 0,
      title: json['title'] ?? 'Conversation',
      lastQuestion: json['last_question'] ?? '',
      lastAnswer: json['last_answer'] ?? '',
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

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

class ThreadMessage {
  final String question;
  final String answer;
  final double confidence;
  final DateTime createdAt;
  final List<Map<String, dynamic>> sources;

  ThreadMessage({
    required this.question,
    required this.answer,
    required this.confidence,
    required this.createdAt,
    required this.sources,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      sources: json['sources'] is List
          ? List<Map<String, dynamic>>.from(json['sources'] as List)
          : [],
    );
  }
}
