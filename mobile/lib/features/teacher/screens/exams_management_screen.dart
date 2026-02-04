import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../courses/models/course_model.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ExamsManagementScreen extends StatefulWidget {
  const ExamsManagementScreen({super.key});

  @override
  State<ExamsManagementScreen> createState() => _ExamsManagementScreenState();
}

class _ExamsManagementScreenState extends State<ExamsManagementScreen> with RouteAware {
  late final CourseService _courseService;
  List<Course> _courses = [];
  final Map<int, List<ExamSummary>> _examsByCourseId = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    _fetchExamManagementData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchExamManagementData();
  }

  Future<void> _fetchExamManagementData() async {
    var hadCache = false;
    final cachedCourses = await CacheService.getJson('cache:teacher:my_courses');
    if (cachedCourses is List) {
      final courses = cachedCourses.map((json) => Course.fromJson(json)).toList();
      final examsByCourse = <int, List<ExamSummary>>{};
      for (final course in courses) {
        final cachedExams = await CacheService.getJson('cache:teacher:exams_by_course:${course.id}');
        if (cachedExams is List) {
          examsByCourse[course.id] = cachedExams
              .map((json) => ExamSummary.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      hadCache = true;
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _examsByCourseId
          ..clear()
          ..addAll(examsByCourse);
        _error = null;
        _isLoading = false;
      });
    }

    if (!hadCache && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final courses = await _courseService.fetchMyCourses();
      final examsByCourse = <int, List<ExamSummary>>{};

      await Future.wait(
        courses.map((course) async {
          final exams = await _courseService.fetchExamsByCourse(course.id);
          examsByCourse[course.id] = exams;
        }),
      );

      setState(() {
        _courses = courses;
        _examsByCourseId
          ..clear()
          ..addAll(examsByCourse);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!hadCache) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams Management'),
        elevation: 0,
      ),
      drawer: const TeacherDrawer(),
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
                        'Failed to load exams',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchExamManagementData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _courses.isEmpty ||
                      !_examsByCourseId.values.any((exams) => exams.isNotEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No exams yet',
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create exams from course detail pages',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchExamManagementData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.where((course) {
                          final exams = _examsByCourseId[course.id] ?? [];
                          return exams.isNotEmpty;
                        }).length,
                        itemBuilder: (context, index) {
                          final coursesWithExams = _courses.where((course) {
                            final exams = _examsByCourseId[course.id] ?? [];
                            return exams.isNotEmpty;
                          }).toList();
                          final course = coursesWithExams[index];
                          final exams = _examsByCourseId[course.id] ?? [];
                          return _buildCourseSection(course, exams);
                        },
                      ),
                    ),
      bottomNavigationBar: const TeacherBottomNav(currentIndex: 1),
    );
  }

  Widget _buildCourseSection(Course course, List<ExamSummary> exams) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${exams.length} exam${exams.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...exams.map((exam) => _buildExamTile(exam)),
        ],
      ),
    );
  }

  Widget _buildExamTile(ExamSummary exam) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: const Icon(Icons.quiz, color: Colors.orange),
      ),
      title: Text(
        exam.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${exam.questionsCount} question${exam.questionsCount == 1 ? '' : 's'}'),
          if ((exam.description ?? '').isNotEmpty)
            Text(
              exam.description!,
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              final result = await context.push('/teacher/exams/${exam.id}');
              if (result == true) {
                await _fetchExamManagementData();
              }
            },
            tooltip: 'View Details',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () async {
              await context.push('/teacher/exams/${exam.id}/submissions');
            },
            tooltip: 'View Submissions',
          ),
        ],
      ),
      onTap: () async {
        final result = await context.push('/teacher/exams/${exam.id}');
        if (result == true) {
          await _fetchExamManagementData();
        }
      },
    );
  }
}






