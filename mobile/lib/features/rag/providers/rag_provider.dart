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

// Provider for current thread id (per course)
final ragThreadIdByCourseProvider = StateProvider<Map<int, String?>>((ref) => {});

// Provider for loading state
final chatLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for query history
final threadHistoryProvider = FutureProvider.family<List<ThreadSummary>, int>((ref, courseId) async {
  final ragService = ref.read(ragServiceProvider);
  final threads = await ragService.getThreads(courseId: courseId);
  return threads.map((item) => ThreadSummary.fromJson(item)).toList();
});
