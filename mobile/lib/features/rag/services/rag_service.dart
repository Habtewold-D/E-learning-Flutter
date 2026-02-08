import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/utils/constants.dart';

class RAGService {
  final ApiClient _apiClient;

  RAGService(this._apiClient);

  /// Ask a question about course materials using AI
  Future<Map<String, dynamic>> askQuestion({
    required int courseId,
    required String question,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.ragAsk,
        data: {
          'course_id': courseId,
          'question': question,
        },
      );
      return response.data;
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
          return data['error']['message'] ?? 'An error occurred';
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

/// Model for AI question response
class QuestionResponse {
  final String answer;
  final double confidence;
  final List<Map<String, dynamic>> sources;
  final int responseTimeMs;

  QuestionResponse({
    required this.answer,
    required this.confidence,
    required this.sources,
    required this.responseTimeMs,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []),
      responseTimeMs: json['response_time_ms'] ?? 0,
    );
  }

  /// Get confidence level as text
  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get confidence color
  String get confidenceColor {
    if (confidence >= 0.8) return 'green';
    if (confidence >= 0.6) return 'orange';
    return 'red';
  }
}

/// Model for query history item
class QueryHistoryItem {
  final int id;
  final String question;
  final String answer;
  final double confidence;
  final int responseTimeMs;
  final String createdAt;
  final List<Map<String, dynamic>> sources;

  QueryHistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.confidence,
    required this.responseTimeMs,
    required this.createdAt,
    required this.sources,
  });

  factory QueryHistoryItem.fromJson(Map<String, dynamic> json) {
    return QueryHistoryItem(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      responseTimeMs: json['response_time_ms'] ?? 0,
      createdAt: json['created_at'] ?? '',
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []),
    );
  }

  /// Format creation date
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}

/// Model for content indexing status
class IndexStatusResponse {
  final int contentId;
  final String status;
  final int chunksCreated;
  final String? lastUpdated;
  final String? errorMessage;

  IndexStatusResponse({
    required this.contentId,
    required this.status,
    required this.chunksCreated,
    this.lastUpdated,
    this.errorMessage,
  });

  factory IndexStatusResponse.fromJson(Map<String, dynamic> json) {
    return IndexStatusResponse(
      contentId: json['content_id'] ?? 0,
      status: json['status'] ?? 'unknown',
      chunksCreated: json['chunks_created'] ?? 0,
      lastUpdated: json['last_updated'],
      errorMessage: json['error_message'],
    );
  }

  /// Check if indexing is complete
  bool get isCompleted => status == 'completed';

  /// Check if indexing is in progress
  bool get isIndexing => status == 'indexing';

  /// Check if indexing failed
  bool get hasError => status == 'not_indexed' && errorMessage != null;

  /// Get status display text
  String get statusText {
    switch (status) {
      case 'completed':
        return 'Indexed';
      case 'indexing':
        return 'Processing...';
      case 'not_indexed':
        return 'Not Indexed';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'completed':
        return 'green';
      case 'indexing':
        return 'blue';
      case 'not_indexed':
        return 'orange';
      default:
        return 'grey';
    }
  }
}
