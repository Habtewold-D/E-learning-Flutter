import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';

class ExamsManagementScreen extends StatefulWidget {
  const ExamsManagementScreen({super.key});

  @override
  State<ExamsManagementScreen> createState() => _ExamsManagementScreenState();
}

class _ExamsManagementScreenState extends State<ExamsManagementScreen> {
  // Mock exams data grouped by course
  final Map<String, List<Map<String, dynamic>>> _examsByCourse = {
    'Introduction to Flutter': [
      {
        'id': 1,
        'title': 'Midterm Exam',
        'questions': 20,
        'duration': 60,
        'submissions': 12,
        'courseId': 1,
      },
      {
        'id': 2,
        'title': 'Final Exam',
        'questions': 30,
        'duration': 90,
        'submissions': 10,
        'courseId': 1,
      },
    ],
    'Advanced React Development': [
      {
        'id': 3,
        'title': 'Quiz 1',
        'questions': 10,
        'duration': 30,
        'submissions': 8,
        'courseId': 2,
      },
      {
        'id': 4,
        'title': 'Final Project Exam',
        'questions': 25,
        'duration': 120,
        'submissions': 5,
        'courseId': 2,
      },
    ],
    'Python Basics for Beginners': [
      {
        'id': 5,
        'title': 'Chapter 1 Quiz',
        'questions': 15,
        'duration': 45,
        'submissions': 6,
        'courseId': 3,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams Management'),
        elevation: 0,
      ),
      drawer: const TeacherDrawer(),
      body: _examsByCourse.isEmpty
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
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _examsByCourse.length,
                itemBuilder: (context, index) {
                  final courseName = _examsByCourse.keys.elementAt(index);
                  final exams = _examsByCourse[courseName]!;
                  return _buildCourseSection(courseName, exams);
                },
              ),
            ),
      bottomNavigationBar: const TeacherBottomNav(currentIndex: 1),
    );
  }

  Widget _buildCourseSection(String courseName, List<Map<String, dynamic>> exams) {
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
                    courseName,
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

  Widget _buildExamTile(Map<String, dynamic> exam) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: const Icon(Icons.quiz, color: Colors.orange),
      ),
      title: Text(
        exam['title'] as String,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${exam['questions']} questions • ${exam['duration']} minutes'),
          Text('${exam['submissions']} submissions'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              context.push('/teacher/exams/${exam['id']}');
            },
            tooltip: 'View Details',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              context.push('/teacher/exams/${exam['id']}/submissions');
            },
            tooltip: 'View Submissions',
          ),
        ],
      ),
      onTap: () => context.push('/teacher/exams/${exam['id']}'),
    );
  }
}






