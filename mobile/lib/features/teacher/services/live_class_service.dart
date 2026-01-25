import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/live_class.dart';

class LiveClassService {
  final ApiClient _apiClient;

  LiveClassService(this._apiClient);

  /// Fetch all live classes for the current teacher
  Future<List<LiveClass>> fetchLiveClasses() async {
    try {
      final response = await _apiClient.get('/live-classes/');
      final List<dynamic> data = response.data;
      return data.map((json) => LiveClass.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new live class
  Future<LiveClass> createLiveClass({
    required int courseId,
    required String title,
    DateTime? scheduledTime,
  }) async {
    try {
      final requestData = {
        'course_id': courseId,
        'title': title,
        if (scheduledTime != null) 'scheduled_time': scheduledTime.toIso8601String(),
      };

      final response = await _apiClient.post('/live-classes/', data: requestData);
      return LiveClass.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start a live class (change status to active)
  Future<LiveClass> startLiveClass(int liveClassId) async {
    try {
      final updateData = {
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.patch('/live-classes/$liveClassId/', data: updateData);
      return LiveClass.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific live class details
  Future<LiveClass> getLiveClass(int liveClassId) async {
    try {
      final response = await _apiClient.get('/live-classes/$liveClassId/');
      return LiveClass.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join a live class (for students, but teacher can also use)
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
          return Exception(data['detail'] ?? 'Access denied.');
        case 404:
          return Exception('Live class not found.');
        case 400:
          return Exception(data['detail'] ?? 'Invalid request.');
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