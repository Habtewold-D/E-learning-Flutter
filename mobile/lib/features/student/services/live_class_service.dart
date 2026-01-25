import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../teacher/models/live_class.dart';

class StudentLiveClassService {
  final ApiClient _apiClient;

  StudentLiveClassService(this._apiClient);

  Future<List<LiveClass>> fetchLiveClasses({String? status}) async {
    try {
      final response = await _apiClient.get(
        '/live-classes/',
        queryParameters: status != null ? {'status': status} : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => LiveClass.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LiveClass> joinLiveClass(int liveClassId) async {
    try {
      final response = await _apiClient.get('/live-classes/$liveClassId/join');
      return LiveClass.fromJson(response.data);
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
          return Exception(data['detail'] ?? 'Class has not started yet.');
        case 404:
          return Exception('Live class not found.');
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
