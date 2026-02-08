import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rag_service.dart';
import '../models/question_response.dart';
import '../models/query_history.dart';

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
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showHistory = false;
  List<QueryHistoryItem> _queryHistory = [];

  @override
  void initState() {
    super.initState();
    _loadQueryHistory();
    // Add welcome message
    _addMessage(
      ChatMessage(
        text: 'Hello! I\'m your AI assistant for "${widget.courseTitle}". I can help you with questions about the course materials. What would you like to know?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _loadQueryHistory() async {
    try {
      // This would be implemented with Riverpod provider
      // For now, showing empty history
      setState(() {
        _queryHistory = [];
      });
    } catch (e) {
      // Handle error
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    setState(() {
      _isLoading = true;
    });

    try {
      // This would call the RAG service
      // For demo purposes, showing a mock response
      await Future.delayed(const Duration(seconds: 2));
      
      _addMessage(
        ChatMessage(
          text: 'This is a demo response. In the actual implementation, this would be an AI-generated answer based on your course materials.',
          isUser: false,
          timestamp: DateTime.now(),
          confidence: 0.85,
          sources: [
            {'title': 'Chapter 1: Introduction', 'page': 15},
            {'title': 'Video Lecture 2', 'timestamp': '12:30'},
          ],
        ),
      );
    } catch (e) {
      _addMessage(
        ChatMessage(
          text: 'Sorry, I encountered an error while processing your question. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant - ${widget.courseTitle}'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.chat : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryView() : _buildChatView(),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Thinking...'),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _queryHistory.length,
      itemBuilder: (context, index) {
        final item = _queryHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              item.question,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.answer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.assessment,
                      size: 14,
                      color: _getConfidenceColor(item.confidence),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(item.confidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getConfidenceColor(item.confidence),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to detailed answer view
            },
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
