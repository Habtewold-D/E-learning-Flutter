class StudentSummary {
  final int id;
  final String name;
  final String email;

  StudentSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
