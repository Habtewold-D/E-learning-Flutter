import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/course_model.dart';

class CourseService {
  final ApiClient _apiClient;

  CourseService(this._apiClient);

  /// Fetch all courses
  Future<List<Course>> fetchCourses() async {
    try {
      final response = await _apiClient.get('/courses/');
      final List<dynamic> data = response.data;
      return data.map((json) => Course.fromJson(json)).toList();
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