class CourseProgress {
  final int courseId;
  final int contentCount;
  final int completedCount;
  final double progress;
  final List<int> completedContentIds;

  CourseProgress({
    required this.courseId,
    required this.contentCount,
    required this.completedCount,
    required this.progress,
    required this.completedContentIds,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['course_id'] as int,
      contentCount: json['content_count'] as int,
      completedCount: json['completed_count'] as int,
      progress: (json['progress'] as num).toDouble(),
      completedContentIds: (json['completed_content_ids'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );
  }
}
