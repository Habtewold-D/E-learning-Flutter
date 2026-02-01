class AdminTrends {
  final String period;
  final List<String> labels;
  final List<int> enrollments;
  final List<int> liveClasses;
  final double enrollmentsChange;
  final double liveClassesChange;

  AdminTrends({
    required this.period,
    required this.labels,
    required this.enrollments,
    required this.liveClasses,
    required this.enrollmentsChange,
    required this.liveClassesChange,
  });

  factory AdminTrends.fromJson(Map<String, dynamic> json) {
    return AdminTrends(
      period: json['period'] as String? ?? 'weekly',
      labels: (json['labels'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      enrollments: (json['enrollments'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList(),
      liveClasses: (json['live_classes'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList(),
      enrollmentsChange: (json['enrollments_change'] as num?)?.toDouble() ?? 0,
      liveClassesChange: (json['live_classes_change'] as num?)?.toDouble() ?? 0,
    );
  }
}
