class EnrolledCourse {
  final int id;
  final String title;
  final String? description;
  final int contentCount;
  final int completedContent;
  final double progress;

  EnrolledCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.contentCount,
    required this.completedContent,
    required this.progress,
  });

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) {
    return EnrolledCourse(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentCount: json['content_count'] as int? ?? 0,
      completedContent: json['completed_content'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}