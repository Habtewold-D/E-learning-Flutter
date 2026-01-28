class ExamSummary {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int questionsCount;

  ExamSummary({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.questionsCount,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>? ?? [];
    return ExamSummary(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      questionsCount: questions.length,
    );
  }
}
