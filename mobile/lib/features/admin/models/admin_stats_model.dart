class AdminStats {
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalAdmins;
  final int totalCourses;
  final int totalContentItems;
  final int totalExams;
  final int totalLiveClasses;
  final int enrollmentsTotal;
  final int enrollmentsPending;
  final int enrollmentsApproved;
  final int enrollmentsRejected;
  final int liveClassesScheduled;
  final int liveClassesActive;
  final int liveClassesEnded;

  AdminStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalAdmins,
    required this.totalCourses,
    required this.totalContentItems,
    required this.totalExams,
    required this.totalLiveClasses,
    required this.enrollmentsTotal,
    required this.enrollmentsPending,
    required this.enrollmentsApproved,
    required this.enrollmentsRejected,
    required this.liveClassesScheduled,
    required this.liveClassesActive,
    required this.liveClassesEnded,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      totalTeachers: json['total_teachers'] as int? ?? 0,
      totalAdmins: json['total_admins'] as int? ?? 0,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalContentItems: json['total_content_items'] as int? ?? 0,
      totalExams: json['total_exams'] as int? ?? 0,
      totalLiveClasses: json['total_live_classes'] as int? ?? 0,
      enrollmentsTotal: json['enrollments_total'] as int? ?? 0,
      enrollmentsPending: json['enrollments_pending'] as int? ?? 0,
      enrollmentsApproved: json['enrollments_approved'] as int? ?? 0,
      enrollmentsRejected: json['enrollments_rejected'] as int? ?? 0,
      liveClassesScheduled: json['live_classes_scheduled'] as int? ?? 0,
      liveClassesActive: json['live_classes_active'] as int? ?? 0,
      liveClassesEnded: json['live_classes_ended'] as int? ?? 0,
    );
  }
}
