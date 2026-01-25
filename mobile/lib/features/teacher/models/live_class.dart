class LiveClass {
  final int id;
  final int courseId;
  final int teacherId;
  final String title;
  final String roomName;
  final String status;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? endedAt;

  LiveClass({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.title,
    required this.roomName,
    required this.status,
    this.scheduledTime,
    this.startedAt,
    this.endedAt,
  });

  factory LiveClass.fromJson(Map<String, dynamic> json) {
    return LiveClass(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      teacherId: json['teacher_id'] as int,
      title: json['title'] as String,
      roomName: json['room_name'] as String,
      status: json['status'] as String,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'title': title,
      'room_name': roomName,
      'status': status,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded => status == 'ended';

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'scheduled':
        return 'Scheduled';
      case 'ended':
        return 'Ended';
      default:
        return status;
    }
  }
}