class CourseBrowse {
  final int id;
  final String title;
  final String? description;
  final int teacherId;
  final String teacherName;
  final int studentsCount;
  final int contentCount;
  final bool isEnrolled;

  CourseBrowse({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.teacherName,
    required this.studentsCount,
    required this.contentCount,
    required this.isEnrolled,
  });

  factory CourseBrowse.fromJson(Map<String, dynamic> json) {
    return CourseBrowse(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as int,
      teacherName: json['teacher_name'] as String? ?? '',
      studentsCount: (json['students_count'] as num?)?.toInt() ?? 0,
      contentCount: (json['content_count'] as num?)?.toInt() ?? 0,
      isEnrolled: json['is_enrolled'] as bool? ?? false,
    );
  }

  CourseBrowse copyWith({
    int? id,
    String? title,
    String? description,
    int? teacherId,
    String? teacherName,
    int? studentsCount,
    int? contentCount,
    bool? isEnrolled,
  }) {
    return CourseBrowse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      studentsCount: studentsCount ?? this.studentsCount,
      contentCount: contentCount ?? this.contentCount,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}
