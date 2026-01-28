import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_content_model.dart';
import '../../exams/models/exam_model.dart';

class CourseService {
  final ApiClient _apiClient;

  CourseService(this._apiClient);

  /// Fetch courses created by current teacher
  Future<List<Course>> fetchMyCourses() async {
    try {
      final response = await _apiClient.get('/courses/teacher/me');
      final List<dynamic> data = response.data;
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch all courses (used by live classes to map course titles)
  Future<List<Course>> fetchCourses() async {
    try {
      final response = await _apiClient.get('/courses/');
      final List<dynamic> data = response.data;
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new course
  Future<Course> createCourse({
    required String title,
    required String description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/courses/',
        data: {
          'title': title,
          'description': description,
        },
      );
      return Course.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch course detail with contents
  Future<Course> fetchCourseDetail(int courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId');
      return Course.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch content list for a course
  Future<List<CourseContent>> fetchCourseContent(int courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId');
      final data = response.data as Map<String, dynamic>;
      final contents = data['contents'] as List<dynamic>? ?? [];
      return contents
          .map((json) => CourseContent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch exams by course
  Future<List<ExamSummary>> fetchExamsByCourse(int courseId) async {
    try {
      final response = await _apiClient.get('/exams/course/$courseId');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => ExamSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch exam detail with questions
  Future<ExamDetail> fetchExamDetail(int examId) async {
    try {
      final response = await _apiClient.get('/exams/$examId');
      return ExamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create exam with questions
  Future<ExamDetail> createExam({
    required int courseId,
    required String title,
    String? description,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final response = await _apiClient.post(
        '/exams/',
        data: {
          'course_id': courseId,
          'title': title,
          'description': description,
          'questions': questions,
        },
      );
      return ExamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update exam title/description
  Future<ExamDetail> updateExam({
    required int examId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/exams/$examId',
        data: data,
      );
      return ExamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add a question to an exam
  Future<ExamQuestion> addExamQuestion({
    required int examId,
    required Map<String, dynamic> question,
  }) async {
    try {
      final response = await _apiClient.post(
        '/exams/$examId/questions',
        data: question,
      );
      return ExamQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing question
  Future<ExamQuestion> updateExamQuestion({
    required int questionId,
    required Map<String, dynamic> question,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/exams/questions/$questionId',
        data: question,
      );
      return ExamQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a question
  Future<void> deleteExamQuestion(int questionId) async {
    try {
      await _apiClient.delete('/exams/questions/$questionId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch submissions for an exam (teacher)
  Future<List<ExamSubmission>> fetchExamSubmissions(int examId) async {
    try {
      final response = await _apiClient.get('/exams/$examId/submissions');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => ExamSubmission.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      switch (statusCode) {
        case 401:
          return Exception('Authentication required. Please log in again.');
        case 403:
          return Exception('Access denied.');
        case 404:
          return Exception('Courses not found.');
        default:
          return Exception('Server error: ${data['detail'] ?? 'Unknown error'}');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Connection failed. Please check if the server is running and accessible.');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}