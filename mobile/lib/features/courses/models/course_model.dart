class Course {
  final int id;
  final String title;
  final String description;
  final int teacherId;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int studentCount;
  final List<CourseContent>? contents;
  final List<Exam>? exams;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    this.teacherName,
    required this.createdAt,
    this.updatedAt,
    this.studentCount = 0,
    this.contents,
    this.exams,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      teacherId: json['teacher_id'] as int? ?? json['teacherId'] as int,
      teacherName: json['teacher_name'] as String? ?? json['teacherName'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(), // Default to now if not provided
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      studentCount: json['student_count'] as int? ?? json['studentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class CourseContent {
  final int id;
  final int courseId;
  final String title;
  final String type; // 'pdf' or 'video'
  final String url;
  final DateTime createdAt;

  CourseContent({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'] as int,
      courseId: json['course_id'] as int? ?? json['courseId'] as int,
      title: json['title'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    );
  }
}

class Exam {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int durationMinutes;
  final DateTime createdAt;
  final int questionCount;
  final bool isCompleted;

  Exam({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.createdAt,
    this.questionCount = 0,
    this.isCompleted = false,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as int,
      courseId: json['course_id'] as int? ?? json['courseId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? json['durationMinutes'] as int? ?? 30,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      questionCount: json['question_count'] as int? ?? json['questionCount'] as int? ?? 0,
    );
  }
}






