import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_bottom_nav.dart';
import '../../../core/widgets/student_drawer.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  // Mock course data
  late Map<String, dynamic> _course;
  final List<Map<String, dynamic>> _content = [];

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  void _loadCourseData() {
    // Mock course
    _course = {
      'id': int.parse(widget.courseId),
      'title': 'Introduction to Flutter',
      'description': 'Learn Flutter from scratch with hands-on projects. This comprehensive course covers everything from basic widgets to advanced state management.',
      'teacher': 'John Teacher',
      'students': 15,
      'contentCount': 8,
      'progress': 45,
    };

    // Mock content
    _content.addAll([
      {
        'id': 1,
        'title': 'Chapter 1: Getting Started',
        'type': 'video',
        'duration': '15:30',
        'isCompleted': true,
      },
      {
        'id': 2,
        'title': 'Chapter 2: Widgets Basics',
        'type': 'video',
        'duration': '20:45',
        'isCompleted': true,
      },
      {
        'id': 3,
        'title': 'Chapter 3: State Management',
        'type': 'video',
        'duration': '25:10',
        'isCompleted': false,
      },
      {
        'id': 4,
        'title': 'Chapter 1 Notes',
        'type': 'pdf',
        'duration': '10 pages',
        'isCompleted': true,
      },
      {
        'id': 5,
        'title': 'Chapter 2 Exercises',
        'type': 'pdf',
        'duration': '5 pages',
        'isCompleted': false,
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course['title'] as String),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: SingleChildScrollView(
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
                    _course['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course['description'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Teacher: ${_course['teacher']}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_course['students']} students',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
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
                            '${_course['progress']}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _course['progress'] / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_content.where((c) => c['isCompleted'] == true).length}/${_content.length} content completed',
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
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Icon(Icons.quiz, color: Colors.orange[800]),
                  ),
                  title: const Text('Midterm Exam'),
                  subtitle: const Text('Due: Dec 30, 2024'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/student/exams?courseId=${widget.courseId}'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item) {
    final isCompleted = item['isCompleted'] as bool;
    final isVideo = item['type'] == 'video';

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
            item['title'] as String,
            style: TextStyle(
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(item['duration'] as String),
          trailing: isCompleted
              ? Icon(Icons.check_circle, color: Colors.green, size: 24)
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (isVideo) {
              context.push('/student/content/${item['id']}?type=video');
            } else {
              context.push('/student/content/${item['id']}?type=pdf');
            }
          },
        ),
      ),
    );
  }
}






