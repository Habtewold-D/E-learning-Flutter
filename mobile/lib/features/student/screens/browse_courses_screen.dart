import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_bottom_nav.dart';
import '../../../core/widgets/student_drawer.dart';

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  // Mock available courses
  final List<Map<String, dynamic>> _allCourses = [
    {
      'id': 1,
      'title': 'Introduction to Flutter',
      'description': 'Learn Flutter from scratch with hands-on projects',
      'teacher': 'John Teacher',
      'students': 15,
      'contentCount': 8,
      'isEnrolled': true,
    },
    {
      'id': 2,
      'title': 'Advanced React Development',
      'description': 'Master React hooks, context, and advanced patterns',
      'teacher': 'Jane Instructor',
      'students': 12,
      'contentCount': 12,
      'isEnrolled': true,
    },
    {
      'id': 3,
      'title': 'Python Basics for Beginners',
      'description': 'Start your programming journey with Python',
      'teacher': 'Bob Teacher',
      'students': 8,
      'contentCount': 10,
      'isEnrolled': true,
    },
    {
      'id': 4,
      'title': 'Database Design & SQL',
      'description': 'Learn to design and query databases effectively',
      'teacher': 'Alice Teacher',
      'students': 5,
      'contentCount': 6,
      'isEnrolled': false,
    },
    {
      'id': 5,
      'title': 'Mobile App UI/UX Design',
      'description': 'Create beautiful and intuitive mobile interfaces',
      'teacher': 'Charlie Designer',
      'students': 2,
      'contentCount': 4,
      'isEnrolled': false,
    },
    {
      'id': 6,
      'title': 'Web Development Fundamentals',
      'description': 'HTML, CSS, and JavaScript basics',
      'teacher': 'David Developer',
      'students': 20,
      'contentCount': 15,
      'isEnrolled': false,
    },
  ];

  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'enrolled', 'available'

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _allCourses.where((course) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = course['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            course['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }

      // Enrollment filter
      if (_filter == 'enrolled') {
        return course['isEnrolled'] == true;
      } else if (_filter == 'available') {
        return course['isEnrolled'] == false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Courses'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == 'all',
                        onSelected: (selected) {
                          if (selected) setState(() => _filter = 'all');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Enrolled'),
                        selected: _filter == 'enrolled',
                        onSelected: (selected) {
                          if (selected) setState(() => _filter = 'enrolled');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Available'),
                        selected: _filter == 'available',
                        onSelected: (selected) {
                          if (selected) setState(() => _filter = 'available');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Courses List
          Expanded(
            child: filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
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
      bottomNavigationBar: const StudentBottomNav(currentIndex: 2),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isEnrolled = course['isEnrolled'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/student/courses/${course['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    child: Icon(
                      Icons.book,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                            if (isEnrolled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Enrolled',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course['description'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    course['teacher'] as String,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course['students']} students',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.description, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course['contentCount']} content',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isEnrolled) {
                      context.push('/student/courses/${course['id']}');
                    } else {
                      _enrollInCourse(course);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnrolled
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEnrolled ? 'Continue Learning' : 'Enroll Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enrollInCourse(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll in Course'),
        content: Text('Are you sure you want to enroll in "${course['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                course['isEnrolled'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully enrolled in ${course['title']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }
}






