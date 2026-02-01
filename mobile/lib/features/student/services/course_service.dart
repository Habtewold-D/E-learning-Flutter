import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
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
    const cacheKey = 'cache:student:browse_courses';
    try {
      final response = await _apiClient.get('/courses/browse');
      final list = response.data as List<dynamic>;
      await CacheService.setJson(cacheKey, list);
      return list
          .map((json) => CourseBrowse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => CourseBrowse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
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
    const cacheKey = 'cache:student:enrolled_courses';
    try {
      final response = await _apiClient.get('/courses/enrolled/me');
      final list = response.data as List<dynamic>;
      await CacheService.setJson(cacheKey, list);
      return list
          .map((json) => EnrolledCourse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => EnrolledCourse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw _handleError(e);
    }
  }

  Future<Course> fetchCourseDetail(int courseId) async {
    final cacheKey = 'cache:student:course_detail:$courseId';
    try {
      final response = await _apiClient.get('/courses/$courseId');
      await CacheService.setJson(cacheKey, response.data);
      return Course.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return Course.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<List<CourseContent>> fetchCourseContent(int courseId) async {
    final cacheKey = 'cache:student:course_content:$courseId';
    try {
      final response = await _apiClient.get('/courses/$courseId');
      final data = response.data as Map<String, dynamic>;
      final contents = data['contents'] as List<dynamic>? ?? [];
      await CacheService.setJson(cacheKey, contents);
      return contents
          .map((json) => CourseContent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => CourseContent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw _handleError(e);
    }
  }

  Future<CourseProgress> fetchCourseProgress(int courseId) async {
    final cacheKey = 'cache:student:course_progress:$courseId';
    try {
      final response = await _apiClient.get('/courses/$courseId/progress');
      await CacheService.setJson(cacheKey, response.data);
      return CourseProgress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return CourseProgress.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<List<ExamSummary>> fetchExamsByCourse(int courseId) async {
    final cacheKey = 'cache:student:exams_by_course:$courseId';
    try {
      final response = await _apiClient.get('/exams/course/$courseId');
      final list = response.data as List<dynamic>;
      await CacheService.setJson(cacheKey, list);
      return list
          .map((json) => ExamSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => ExamSummary.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw _handleError(e);
    }
  }

  Future<ExamDetail> fetchExamDetail(int examId) async {
    final cacheKey = 'cache:student:exam_detail:$examId';
    try {
      final response = await _apiClient.get('/exams/$examId');
      await CacheService.setJson(cacheKey, response.data);
      return ExamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return ExamDetail.fromJson(cached);
      }
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
    final cacheKey = 'cache:student:exam_result:$examId';
    try {
      final response = await _apiClient.get('/exams/$examId/results');
      final list = response.data as List<dynamic>;
      if (list.isEmpty) return null;
      await CacheService.setJson(cacheKey, list.first);
      return ExamResult.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is Map<String, dynamic>) {
        return ExamResult.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<List<StudentExamListItem>> fetchMyExams({int? courseId}) async {
    final cacheKey = 'cache:student:my_exams:${courseId ?? 'all'}';
    try {
      final response = await _apiClient.get(
        '/exams/my',
        queryParameters: courseId != null ? {'course_id': courseId} : null,
      );
      final list = response.data as List<dynamic>;
      await CacheService.setJson(cacheKey, list);
      return list
          .map((json) => StudentExamListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final cached = await CacheService.getJson(cacheKey);
      if (cached is List) {
        return cached
            .map((json) => StudentExamListItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
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
