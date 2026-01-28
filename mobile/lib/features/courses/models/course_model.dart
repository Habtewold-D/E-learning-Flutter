class Course {
  final int id;
  final String title;
  final String? description;
  final int? teacherId;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.teacherId,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
