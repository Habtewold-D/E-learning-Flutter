import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock course data
    final course = {
      'id': int.parse(courseId),
      'title': 'Introduction to Flutter',
      'description': 'Learn Flutter from scratch with hands-on projects. This course covers everything from basic widgets to state management and API integration.',
      'students': 15,
      'createdAt': '2024-01-15',
    };

    // Mock content
    final contents = [
      {'id': 1, 'title': 'Chapter 1: Getting Started', 'type': 'pdf', 'url': 'chapter1.pdf'},
      {'id': 2, 'title': 'Chapter 2: Widgets Basics', 'type': 'pdf', 'url': 'chapter2.pdf'},
      {'id': 3, 'title': 'Flutter Setup Tutorial', 'type': 'video', 'url': 'setup.mp4'},
      {'id': 4, 'title': 'Chapter 3: State Management', 'type': 'pdf', 'url': 'chapter3.pdf'},
    ];

    // Mock exams
    final exams = [
      {'id': 1, 'title': 'Midterm Exam', 'questions': 20, 'duration': 60},
      {'id': 2, 'title': 'Final Exam', 'questions': 30, 'duration': 90},
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(course['title'] as String),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit course (coming soon)')),
                );
              },
            ),
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
                  _showDeleteDialog(context, course['title'] as String);
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
        body: TabBarView(
          children: [
            _buildOverviewTab(context, course, contents, exams),
            _buildContentTab(context, contents, courseId),
            _buildExamsTab(context, exams, courseId),
          ],
        ),
        bottomNavigationBar: const TeacherBottomNav(currentIndex: 1),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/teacher/courses/$courseId/upload-content'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Content'),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Map<String, dynamic> course,
    List<Map<String, dynamic>> contents,
    List<Map<String, dynamic>> exams,
  ) {
    return SingleChildScrollView(
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
                  _buildInfoRow('Description', course['description'] as String),
                  const Divider(),
                  _buildInfoRow('Students Enrolled', '${course['students']}'),
                  _buildInfoRow('Content Items', '${contents.length}'),
                  _buildInfoRow('Exams', '${exams.length}'),
                  _buildInfoRow('Created', course['createdAt'] as String),
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
                  value: '${course['students']}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.description,
                  title: 'Content',
                  value: '${contents.length}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.quiz,
                  title: 'Exams',
                  value: '${exams.length}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab(
    BuildContext context,
    List<Map<String, dynamic>> contents,
    String courseId,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Content (${contents.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/teacher/courses/$courseId/upload-content'),
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
              ),
            ],
          ),
        ),
        Expanded(
          child: contents.isEmpty
              ? Center(
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
                        onPressed: () => context.push('/teacher/courses/$courseId/upload-content'),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload First Content'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    return _buildContentCard(context, content);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExamsTab(
    BuildContext context,
    List<Map<String, dynamic>> exams,
    String courseId,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exams (${exams.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/teacher/courses/$courseId/create-exam'),
                icon: const Icon(Icons.add),
                label: const Text('Create Exam'),
              ),
            ],
          ),
        ),
        Expanded(
          child: exams.isEmpty
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
                      ElevatedButton.icon(
                        onPressed: () => context.push('/teacher/courses/$courseId/create-exam'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Exam'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return _buildExamCard(context, exam, courseId);
                  },
                ),
        ),
      ],
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

  Widget _buildContentCard(BuildContext context, Map<String, dynamic> content) {
    final isPdf = content['type'] == 'pdf';
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
          content['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isPdf ? 'PDF Document' : 'Video',
          style: TextStyle(color: Colors.grey[600]),
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${content['title']} deleted (mock)')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, String courseId) {
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
          exam['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${exam['questions']} questions • ${exam['duration']} minutes'),
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
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
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
                if (value == 'edit') {
                  context.push('/teacher/courses/$courseId/create-exam?examId=${exam['id']}');
                } else if (value == 'delete') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${exam['title']} deleted (mock)')),
                  );
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
}

