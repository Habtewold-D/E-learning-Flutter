import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_content_model.dart';
import '../../courses/models/student_summary_model.dart';
import '../../exams/models/exam_model.dart';
import 'content_viewer_screen.dart';
import '../services/course_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CourseService _courseService;
  Course? _course;
  List<CourseContent> _contents = [];
  List<ExamSummary> _exams = [];
  List<StudentSummary> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    var hadCache = false;

    final courseId = int.tryParse(widget.courseId);
    if (courseId == null) {
      setState(() {
        _error = 'Invalid course id';
        _isLoading = false;
      });
      return;
    }

    final cachedCourse = await CacheService.getJson('cache:teacher:course_detail:$courseId');
    final cachedContents = await CacheService.getJson('cache:teacher:course_content:$courseId');
    final cachedExams = await CacheService.getJson('cache:teacher:exams_by_course:$courseId');
    final cachedStudents = await CacheService.getJson('cache:teacher:course_students:$courseId');

    if (cachedCourse is Map<String, dynamic> ||
        cachedContents is List ||
        cachedExams is List ||
        cachedStudents is List) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        if (cachedCourse is Map<String, dynamic>) {
          _course = Course.fromJson(cachedCourse);
        }
        if (cachedContents is List) {
          _contents = cachedContents
              .map((json) => CourseContent.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        if (cachedExams is List) {
          _exams = cachedExams
              .map((json) => ExamSummary.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        if (cachedStudents is List) {
          _students = cachedStudents
              .map((json) => StudentSummary.fromJson(json as Map<String, dynamic>))
              .toList();
        }
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
      final results = await Future.wait([
        _courseService.fetchCourseDetail(courseId),
        _courseService.fetchCourseContent(courseId),
        _courseService.fetchExamsByCourse(courseId),
        _courseService.fetchCourseStudents(courseId),
      ]);

      setState(() {
        _course = results[0] as Course;
        _contents = results[1] as List<CourseContent>;
        _exams = results[2] as List<ExamSummary>;
        _students = results[3] as List<StudentSummary>;
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_course?.title ?? 'Course'),
          elevation: 0,
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Course', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context, _course?.title ?? 'Course');
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Content'),
              Tab(text: 'Exams'),
            ],
          ),
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
                : TabBarView(
                    children: [
                      _buildOverviewTab(context),
                      _buildContentTab(context),
                      _buildExamsTab(context),
                    ],
                  ),
        bottomNavigationBar: const TeacherBottomNav(currentIndex: 1),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final updated = await context.push('/teacher/courses/${widget.courseId}/upload-content');
            if (updated == true) {
              _loadCourseData();
            }
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Content'),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
  ) {
    return RefreshIndicator(
      onRefresh: _loadCourseData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Description', _course?.description ?? ''),
                    const Divider(),
                    _buildInfoRow('Students Enrolled', '${_students.length}'),
                    _buildInfoRow('Content Items', '${_contents.length}'),
                    _buildInfoRow('Exams', '${_exams.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.people,
                    title: 'Students',
                    value: '${_students.length}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.description,
                    title: 'Content',
                    value: '${_contents.length}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.quiz,
                    title: 'Exams',
                    value: '${_exams.length}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Enrolled Students',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_students.isEmpty)
              _buildEmptyStudentsCard()
            else
              ..._students.map(_buildStudentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStudentsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.people_outline, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No students enrolled yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentSummary student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(student.name.isNotEmpty ? student.name : 'Student ${student.id}'),
        subtitle: Text(student.email),
      ),
    );
  }

  Widget _buildContentTab(
    BuildContext context,
  ) {
    return RefreshIndicator(
      onRefresh: _loadCourseData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Course Content (${_contents.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated =
                          await context.push('/teacher/courses/${widget.courseId}/upload-content');
                      if (updated == true) {
                        _loadCourseData();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Content'),
                  ),
                ],
              ),
            ),
            if (_contents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No content yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final updated =
                            await context.push('/teacher/courses/${widget.courseId}/upload-content');
                        if (updated == true) {
                          _loadCourseData();
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload First Content'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _contents.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final content = _contents[index];
                  return _buildContentCard(context, content);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsTab(
    BuildContext context,
  ) {
    return RefreshIndicator(
      onRefresh: _loadCourseData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exams (${_exams.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/teacher/courses/${widget.courseId}/create-exam'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Exam'),
                  ),
                ],
              ),
            ),
            if (_exams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
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
                    ElevatedButton.icon(
                      onPressed: () => context.push('/teacher/courses/${widget.courseId}/create-exam'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Exam'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exams.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final exam = _exams[index];
                  return _buildExamCard(context, exam, widget.courseId);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, CourseContent content) {
    final isPdf = content.type == 'pdf';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isPdf ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            isPdf ? Icons.picture_as_pdf : Icons.video_library,
            color: isPdf ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isPdf ? 'PDF Document' : 'Video',
          style: TextStyle(color: Colors.grey[600]),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeacherContentViewerScreen(
                title: content.title,
                type: content.type,
                url: content.url,
              ),
            ),
          );
        },
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDeleteContent(content);
            }
          },
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamSummary exam, String courseId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
            Text('${exam.questionsCount} questions'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                context.push('/teacher/exams/${exam.id}');
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteExam(exam);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String courseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$courseTitle"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$courseTitle deleted (mock)')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteContent(CourseContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Delete "${content.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _courseService.deleteCourseContent(
                  courseId: int.parse(widget.courseId),
                  contentId: content.id,
                );
                await _loadCourseData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Content deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExam(ExamSummary exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Delete "${exam.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _courseService.deleteExam(exam.id);
                await _loadCourseData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exam deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}






