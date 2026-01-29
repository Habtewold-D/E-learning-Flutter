class ExamSummary {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int questionsCount;

  ExamSummary({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.questionsCount,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>? ?? [];
    return ExamSummary(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      questionsCount: questions.length,
    );
  }
}

class ExamQuestion {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;

  ExamQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as int,
      question: (json['question'] ?? '').toString(),
      optionA: (json['option_a'] ?? '').toString(),
      optionB: (json['option_b'] ?? '').toString(),
      optionC: (json['option_c'] ?? '').toString(),
      optionD: (json['option_d'] ?? '').toString(),
      correctOption: (json['correct_option'] ?? '').toString(),
    );
  }
}

class ExamDetail {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final List<ExamQuestion> questions;

  ExamDetail({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.questions,
  });

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>? ?? [];
    return ExamDetail(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions: questions
          .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExamSubmission {
  final int id;
  final int examId;
  final int studentId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final String studentName;
  final String studentEmail;

  ExamSubmission({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.studentName,
    required this.studentEmail,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) {
    return ExamSubmission(
      id: json['id'] as int,
      examId: json['exam_id'] as int,
      studentId: json['student_id'] as int,
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int,
      studentName: json['student_name'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
    );
  }
}

class StudentExamListItem {
  final int id;
  final int courseId;
  final String courseTitle;
  final String title;
  final String? description;
  final int questionsCount;
  final String status; // 'available' or 'completed'
  final double? score;

  StudentExamListItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    this.description,
    required this.questionsCount,
    required this.status,
    this.score,
  });

  factory StudentExamListItem.fromJson(Map<String, dynamic> json) {
    return StudentExamListItem(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      courseTitle: json['course_title'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      questionsCount: json['questions_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'available',
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  StudentExamListItem copyWith({
    int? id,
    int? courseId,
    String? courseTitle,
    String? title,
    String? description,
    int? questionsCount,
    String? status,
    double? score,
  }) {
    return StudentExamListItem(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      questionsCount: questionsCount ?? this.questionsCount,
      status: status ?? this.status,
      score: score ?? this.score,
    );
  }
}

class ExamResult {
  final int id;
  final int examId;
  final int studentId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;

  ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'] as int,
      examId: json['exam_id'] as int,
      studentId: json['student_id'] as int,
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int,
    );
  }
}
