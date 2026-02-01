class EnrollmentRequest {
  final int id;
  final int courseId;
  final String courseTitle;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String status;
  final String? requestedAt;

  EnrollmentRequest({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.requestedAt,
  });

  factory EnrollmentRequest.fromJson(Map<String, dynamic> json) {
    return EnrollmentRequest(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      courseTitle: json['course_title'] as String? ?? '',
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      requestedAt: json['requested_at'] as String?,
    );
  }
}
