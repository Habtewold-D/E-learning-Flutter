import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/rag_service.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/course_model.dart';
import '../../teacher/services/course_service.dart';

class AdminRAGContentScreen extends ConsumerStatefulWidget {
  const AdminRAGContentScreen({super.key});

  @override
  ConsumerState<AdminRAGContentScreen> createState() => _AdminRAGContentScreenState();
}

class _AdminRAGContentScreenState extends ConsumerState<AdminRAGContentScreen> {
  late final CourseService _courseService;
  late final RAGService _ragService;
  List<Course> _courses = [];
  List<Map<String, dynamic>> _contents = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    _ragService = RAGService(ApiClient());
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _courseService.fetchCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
          _errorMessage = null;
        });
        // Load content for each course
        await _loadContentStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadContentStatus() async {
    setState(() => _isLoading = true);
    try {
      // Load content for all courses
      final allContents = <Map<String, dynamic>>[];
      
      for (final course in _courses) {
        try {
          // Get course content
          final contents = await _courseService.fetchCourseContent(course.id);
          
          // Get RAG status for each content
          for (final content in contents) {
            try {
              final ragStatus = await _ragService.getIndexStatus(content.id);
              allContents.add({
                'id': content.id,
                'title': content.title ?? 'Untitled Content',
                'type': content.type ?? 'unknown',
                'rag_status': ragStatus['status'] ?? 'not_indexed',
                'chunks_count': ragStatus['chunks_created'] ?? 0,
                'last_updated': ragStatus['last_updated'],
                'course_title': course.title,
              });
            } catch (e) {
              // If RAG status fails, add with default status
              allContents.add({
                'id': content.id,
                'title': content.title ?? 'Untitled Content',
                'type': content.type ?? 'unknown',
                'rag_status': 'not_indexed',
                'chunks_count': 0,
                'last_updated': null,
                'course_title': course.title,
              });
            }
          }
        } catch (e) {
          // Continue with other courses if one fails
          continue;
        }
      }
      
      if (mounted) {
        setState(() {
          _contents = allContents;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _indexContent(int contentId) async {
    try {
      setState(() => _isLoading = true);
      
      // Call RAG indexing API
      await _ragService.indexContent(contentId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content indexing started. This may take a few minutes.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh status after a delay
      await Future.delayed(const Duration(seconds: 2));
      _loadContentStatus();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error indexing content: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'indexing':
        return Colors.orange;
      case 'not_indexed':
        return Colors.red;
      case 'not_supported':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Indexed';
      case 'indexing':
        return 'Processing...';
      case 'not_indexed':
        return 'Not Indexed';
      case 'not_supported':
        return 'Not Supported';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'indexing':
        return Icons.refresh;
      case 'not_indexed':
        return Icons.error;
      case 'not_supported':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Content Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin/home');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _contents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadContentStatus,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contents.length,
                        itemBuilder: (context, index) {
                          final content = _contents[index];
                          final status = content['rag_status'] as String;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              content['title'] as String,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Course: ${content['course_title'] as String}',
                                              style: TextStyle(
                                                color: Colors.grey[600]!,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(status),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(status),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Type: ${content['type']}'.toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.grey[600]!,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (status == 'completed') ...[
                                    Text(
                                      'Chunks: ${content['chunks_count']}',
                                      style: TextStyle(
                                        color: Colors.grey[600]!,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (content['last_updated'] != null)
                                      Text(
                                        'Last updated: ${content['last_updated']}',
                                        style: TextStyle(
                                          color: Colors.grey[600]!,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                  if (status == 'not_indexed') ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _indexContent(content['id'] as int),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Index for RAG'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadContentStatus,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Status',
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Content Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload PDF course materials to enable AI assistance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to course creation or content upload
              context.go('/teacher/courses');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
