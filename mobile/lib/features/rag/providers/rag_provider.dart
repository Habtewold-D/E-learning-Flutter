import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rag_service.dart';
import '../models/query_history.dart';
import '../../../core/api/api_client.dart';

// Provider for RAG service
final ragServiceProvider = Provider<RAGService>((ref) {
  return RAGService(ApiClient());
});

// Provider for current chat messages (per course)
final chatMessagesByCourseProvider = StateProvider<Map<int, List<Map<String, dynamic>>>>((ref) => {});

// Provider for loading state
final chatLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for query history
final queryHistoryProvider = FutureProvider.family<List<QueryHistoryItem>, int>((ref, courseId) async {
  final ragService = ref.read(ragServiceProvider);
  final history = await ragService.getQueryHistory(courseId: courseId);
  return history.map((item) => QueryHistoryItem.fromJson(item)).toList();
});
