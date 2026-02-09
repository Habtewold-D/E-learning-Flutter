import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import 'package:dio/dio.dart';

class RAGService {
  final ApiClient _apiClient;

  RAGService(this._apiClient);

  /// Ask a question about course materials using AI
  Future<Map<String, dynamic>> askQuestion({
    required int courseId,
    required String question,
    String? threadId,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.ragAsk,
        data: {
          'course_id': courseId,
          'question': question,
          if (threadId != null) 'thread_id': threadId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// List conversation threads
  Future<List<Map<String, dynamic>>> getThreads({int? courseId}) async {
    try {
      String url = AppConstants.ragThreads;
      if (courseId != null) {
        url += '?course_id=$courseId';
      }
      final response = await _apiClient.get(url);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get messages for a thread
  Future<List<Map<String, dynamic>>> getThreadMessages(String threadId) async {
    try {
      final response = await _apiClient.get(
        AppConstants.ragThreadMessages.replaceAll('{thread_id}', threadId),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get student's question history
  Future<List<Map<String, dynamic>>> getQueryHistory({
    int? courseId,
  }) async {
    try {
      String url = AppConstants.ragHistory;
      if (courseId != null) {
        url += '?course_id=$courseId';
      }

      final response = await _apiClient.get(url);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get indexing status for course content
  Future<Map<String, dynamic>> getIndexStatus(int contentId) async {
    try {
      final response = await _apiClient.get(
        AppConstants.ragIndexStatus.replaceAll('{content_id}', contentId.toString()),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Index course content for RAG (teachers only)
  Future<Map<String, dynamic>> indexContent(int contentId) async {
    try {
      final response = await _apiClient.post(
        AppConstants.ragIndexContent.replaceAll('{content_id}', contentId.toString()),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        if (e.response?.data != null) {
          final data = e.response!.data as Map<String, dynamic>;
          if (data['detail'] != null) {
            return data['detail'].toString();
          }
          if (data['error'] is Map && (data['error'] as Map)['message'] != null) {
            return (data['error'] as Map)['message'].toString();
          }
          return data.toString();
        }
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
