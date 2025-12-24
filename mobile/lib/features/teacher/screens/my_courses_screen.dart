import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  // Mock courses data
  final List<Map<String, dynamic>> _courses = [
    {
      'id': 1,
      'title': 'Introduction to Flutter',
      'description': 'Learn Flutter from scratch with hands-on projects',
      'students': 15,
      'contentCount': 8,
      'examCount': 2,
      'createdAt': '2024-01-15',
    },
    {
      'id': 2,
      'title': 'Advanced React Development',
      'description': 'Master React hooks, context, and advanced patterns',
      'students': 12,
      'contentCount': 12,
      'examCount': 3,
      'createdAt': '2024-01-20',
    },
    {
      'id': 3,
      'title': 'Python Basics for Beginners',
      'description': 'Start your programming journey with Python',
      'students': 8,
      'contentCount': 10,
      'examCount': 2,
      'createdAt': '2024-02-01',
    },
    {
      'id': 4,
      'title': 'Database Design & SQL',
      'description': 'Learn to design and query databases effectively',
      'students': 5,
      'contentCount': 6,
      'examCount': 1,
      'createdAt': '2024-02-10',
    },
    {
      'id': 5,
      'title': 'Mobile App UI/UX Design',
      'description': 'Create beautiful and intuitive mobile interfaces',
      'students': 2,
      'contentCount': 4,
      'examCount': 1,
      'createdAt': '2024-02-15',
    },
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _courses.where((course) {
      if (_searchQuery.isEmpty) return true;
      return course['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/teacher/create-course'),
            tooltip: 'Create Course',
          ),
        ],
      ),
      drawer: const TeacherDrawer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Courses List
          Expanded(
            child: filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No courses yet'
                              : 'No courses found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/teacher/create-course'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Your First Course'),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        return _buildCourseCard(course);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const TeacherBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teacher/create-course'),
        child: const Icon(Icons.add),
        tooltip: 'Create Course',
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/teacher/courses/${course['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
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
                        // Edit course
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit course (coming soon)')),
                        );
                      } else if (value == 'delete') {
                        // Delete course
                        _showDeleteDialog(course);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course['description'] as String,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${course['students']} students',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.description,
                    label: '${course['contentCount']} content',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.quiz,
                    label: '${course['examCount']} exams',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${course['createdAt']}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${course['title']} deleted (mock)')),
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


