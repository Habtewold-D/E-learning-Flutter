import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_bottom_nav.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_content_model.dart';
import '../../courses/models/course_progress_model.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final StudentCourseService _courseService;
  Course? _course;
  List<CourseContent> _content = [];
  CourseProgress? _progress;
  List<ExamSummary> _exams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final courseId = int.tryParse(widget.courseId);
    if (courseId == null) {
      setState(() {
        _error = 'Invalid course id';
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _courseService.fetchCourseDetail(courseId),
        _courseService.fetchCourseContent(courseId),
        _courseService.fetchCourseProgress(courseId),
        _courseService.fetchExamsByCourse(courseId),
      ]);

      setState(() {
        _course = results[0] as Course;
        _content = results[1] as List<CourseContent>;
        _progress = results[2] as CourseProgress;
        _exams = results[3] as List<ExamSummary>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.title ?? 'Course'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load course',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCourseData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _course?.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course?.description ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Progress Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Progress',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${_progress?.progress.toStringAsFixed(0) ?? '0'}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_progress?.progress ?? 0) / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_progress?.completedCount ?? 0}/${_progress?.contentCount ?? 0} content completed',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Course Content',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ..._content.map((item) => _buildContentItem(item)),
            const SizedBox(height: 16),

            // Exams Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exams',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/student/exams?courseId=${widget.courseId}'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _exams.isEmpty
                  ? Text(
                      'No exams yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    )
                  : Column(
                      children: _exams.map((exam) {
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange[100],
                              child: Icon(Icons.quiz, color: Colors.orange[800]),
                            ),
                            title: Text(exam.title),
                            subtitle: Text('${exam.questionsCount} questions'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context.push('/student/exams?courseId=${widget.courseId}'),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
                ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
    );
  }

  Future<void> _refreshProgress(int courseId) async {
    try {
      final progress = await _courseService.fetchCourseProgress(courseId);
      if (!mounted) return;
      setState(() {
        _progress = progress;
      });
    } catch (_) {
      // Ignore progress refresh errors silently.
    }
  }

  Widget _buildContentItem(CourseContent item) {
    final isCompleted = _progress?.completedContentIds.contains(item.id) ?? false;
    final isVideo = item.type == 'video';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: isVideo
                ? Colors.red[100]
                : Colors.blue[100],
            child: Icon(
              isVideo ? Icons.play_circle : Icons.picture_as_pdf,
              color: isVideo ? Colors.red[800] : Colors.blue[800],
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(isVideo ? 'Video' : 'PDF'),
          trailing: isCompleted
              ? Icon(Icons.check_circle, color: Colors.green, size: 24)
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final courseId = int.tryParse(widget.courseId);
            if (courseId == null) return;

            if (!isCompleted) {
              await _courseService.markContentComplete(courseId, item.id);
              await _refreshProgress(courseId);
            }

            if (!mounted) return;
            await context.push(
              '/student/content/${item.id}',
              extra: {
                'title': item.title,
                'type': item.type,
                'url': item.url,
              },
            );

            await _refreshProgress(courseId);
          },
        ),
      ),
    );
  }
}






