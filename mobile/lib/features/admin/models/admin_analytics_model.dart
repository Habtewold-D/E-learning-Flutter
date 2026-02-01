class AdminAnalytics {
  final int enrollmentsPending;
  final int enrollmentsApproved;
  final int enrollmentsRejected;
  final int liveClassesScheduled;
  final int liveClassesActive;
  final int liveClassesEnded;

  AdminAnalytics({
    required this.enrollmentsPending,
    required this.enrollmentsApproved,
    required this.enrollmentsRejected,
    required this.liveClassesScheduled,
    required this.liveClassesActive,
    required this.liveClassesEnded,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      enrollmentsPending: json['enrollments_pending'] as int? ?? 0,
      enrollmentsApproved: json['enrollments_approved'] as int? ?? 0,
      enrollmentsRejected: json['enrollments_rejected'] as int? ?? 0,
      liveClassesScheduled: json['live_classes_scheduled'] as int? ?? 0,
      liveClassesActive: json['live_classes_active'] as int? ?? 0,
      liveClassesEnded: json['live_classes_ended'] as int? ?? 0,
    );
  }
}
