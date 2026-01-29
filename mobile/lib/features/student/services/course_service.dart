import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_browse_model.dart';
import '../../courses/models/course_content_model.dart';
import '../../courses/models/course_progress_model.dart';
import '../../courses/models/enrolled_course_model.dart';
import '../../exams/models/exam_model.dart';

class StudentCourseService {
  final ApiClient _apiClient;

  StudentCourseService(this._apiClient);

  Future<List<CourseBrowse>> fetchBrowseCourses() async {
    try {
      final response = await _apiClient.get('/courses/browse');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => CourseBrowse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> enrollInCourse(int courseId) async {
    try {
      await _apiClient.post('/courses/$courseId/enroll');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<EnrolledCourse>> fetchEnrolledCourses() async {
    try {
      final response = await _apiClient.get('/courses/enrolled/me');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => EnrolledCourse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Course> fetchCourseDetail(int courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId');
      return Course.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  Future<CourseProgress> fetchCourseProgress(int courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId/progress');
      return CourseProgress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  Future<ExamDetail> fetchExamDetail(int examId) async {
    try {
      final response = await _apiClient.get('/exams/$examId');
      return ExamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExamResult> submitExam(int examId, Map<int, String> answers) async {
    try {
      final payloadAnswers = answers.map((key, value) => MapEntry(key.toString(), value));
      final response = await _apiClient.post(
        '/exams/$examId/submit',
        data: {
          'answers': payloadAnswers,
        },
      );
      return ExamResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExamResult?> fetchMyExamResult(int examId) async {
    try {
      final response = await _apiClient.get('/exams/$examId/results');
      final list = response.data as List<dynamic>;
      if (list.isEmpty) return null;
      return ExamResult.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<StudentExamListItem>> fetchMyExams({int? courseId}) async {
    try {
      final response = await _apiClient.get(
        '/exams/my',
        queryParameters: courseId != null ? {'course_id': courseId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) => StudentExamListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markContentComplete(int courseId, int contentId) async {
    try {
      await _apiClient.post('/courses/$courseId/content/$contentId/complete');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      String detail;
      if (data is Map<String, dynamic> && data['detail'] != null) {
        detail = data['detail'].toString();
      } else if (data is String) {
        detail = data;
      } else {
        detail = 'Unknown error';
      }

      switch (statusCode) {
        case 401:
          return Exception('Authentication required. Please log in again.');
        case 403:
          return Exception(detail.isNotEmpty ? detail : 'Access denied.');
        case 404:
          return Exception(detail.isNotEmpty ? detail : 'Not found.');
        case 400:
          return Exception(detail.isNotEmpty ? detail : 'Invalid request.');
        default:
          return Exception('Server error: $detail');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Connection failed. Please check if the server is running and accessible.');
    } else {
      final message = (e.message == null || e.message!.trim().isEmpty)
          ? 'Network error. Please try again.'
          : 'Network error: ${e.message}';
      return Exception(message);
    }
  }
}
