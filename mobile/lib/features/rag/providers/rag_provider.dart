import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rag_service.dart';
import '../models/query_history.dart';
import '../../../core/api/api_client.dart';

// Provider for RAG service
final ragServiceProvider = Provider<RAGService>((ref) {
  return RAGService(ApiClient());
});

// Provider for current chat messages
final chatMessagesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Provider for loading state
final chatLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for query history
final queryHistoryProvider = FutureProvider<List<QueryHistoryItem>>((ref) async {
  final ragService = ref.read(ragServiceProvider);
  final history = await ragService.getQueryHistory();
  return history.map((item) => QueryHistoryItem.fromJson(item)).toList();
});
