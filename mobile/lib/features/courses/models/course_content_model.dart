class CourseContent {
  final int id;
  final int courseId;
  final String title;
  final String type; // 'video' or 'pdf'
  final String url;

  CourseContent({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.url,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
    );
  }
}
