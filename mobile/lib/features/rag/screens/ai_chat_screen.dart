import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/rag_service.dart';
import '../models/question_response.dart';
import '../models/query_history.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../providers/rag_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final int courseId;
  final String courseTitle;

  const AIChatScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage(
        ChatMessage(
          text: 'Hello! I\'m your AI assistant for "${widget.courseTitle}". I can help you with questions about the course materials. What would you like to know?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _addMessage(ChatMessage message) {
    final messages = ref.read(chatMessagesProvider.notifier);
    messages.state = [...messages.state, {
      'text': message.text,
      'isUser': message.isUser,
      'timestamp': message.timestamp,
      'confidence': message.confidence,
      'sources': message.sources,
      'isError': message.isError,
    }];
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Add user message
    _addMessage(
      ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    // Clear input
    _questionController.clear();

    // Show loading
    ref.read(chatLoadingProvider.notifier).state = true;

    try {
      // Use real RAG service
      final apiClient = ApiClient();
      final ragService = RAGService(apiClient);
      
      final result = await ragService.askQuestion(
        courseId: widget.courseId,
        question: question,
      );

      final answer = result['answer']?.toString() ?? '';
      final confidence = (result['confidence'] as num?)?.toDouble();
      final sourcesRaw = result['sources'];
      final sources = sourcesRaw is List
          ? sourcesRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : null;

      // Add AI response
      _addMessage(
        ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
          confidence: confidence,
          sources: sources,
        ),
      );

    } catch (e) {
      _addMessage(
        ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      ref.read(chatLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant - ${widget.courseTitle}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/student/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.chat : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            tooltip: _showHistory ? 'Chat View' : 'Query History',
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryView() : _buildChatView(messages, isLoading),
    );
  }

  Widget _buildChatView(List<Map<String, dynamic>> messages, bool isLoading) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageData = messages[index];
              return _buildMessageBubble(ChatMessage(
                text: messageData['text'] as String,
                isUser: messageData['isUser'] as bool,
                timestamp: messageData['timestamp'] as DateTime,
                confidence: messageData['confidence'] as double?,
                sources: messageData['sources'] as List<Map<String, dynamic>>?,
                isError: messageData['isError'] as bool? ?? false,
              ));
            },
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('Thinking...'),
              ],
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Theme.of(context).colorScheme.primary
                        : message.isError 
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: message.isError 
                        ? Border.all(color: Colors.red.shade200)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser 
                              ? Colors.white
                              : message.isError 
                                  ? Colors.red.shade700
                                  : Colors.black87,
                        ),
                      ),
                      if (message.confidence != null && !message.isUser) ...[
                        const SizedBox(height: 8),
                        _buildConfidenceIndicator(message.confidence!),
                      ],
                      if (message.sources != null && message.sources!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSourcesList(message.sources!),
                      ],
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: message.isUser ? 0 : 40,
              right: message.isUser ? 40 : 0,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    String text;
    
    if (confidence >= 0.8) {
      color = Colors.green;
      text = 'High Confidence';
    } else if (confidence >= 0.6) {
      color = Colors.orange;
      text = 'Medium Confidence';
    } else {
      color = Colors.red;
      text = 'Low Confidence';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesList(List<Map<String, dynamic>> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sources:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        ...sources.map((source) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Icon(
                Icons.source,
                size: 12,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  source['title'] ?? 'Unknown Source',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question about the course...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askQuestion(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : _askQuestion,
            mini: true,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Consumer(
      builder: (context, ref, child) {
        final queryHistoryAsync = ref.watch(queryHistoryProvider);
        
        return queryHistoryAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No questions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start asking questions about your course materials!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      item.question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item.answer.length > 100 
                          ? '${item.answer.substring(0, 100)}...'
                          : item.answer,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(item.confidence * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getConfidenceColor(item.confidence),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to detailed answer view
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? confidence;
  final List<Map<String, dynamic>>? sources;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.confidence,
    this.sources,
    this.isError = false,
  });
}
