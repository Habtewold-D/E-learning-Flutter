import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/student_bottom_nav.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../courses/models/course_browse_model.dart';
import '../services/course_service.dart';

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  late final StudentCourseService _courseService;
  List<CourseBrowse> _allCourses = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'enrolled', 'available'

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _courseService.fetchBrowseCourses();
      if (!mounted) return;
      setState(() {
        _allCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _allCourses.where((course) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (course.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }

      // Enrollment filter
      if (_filter == 'enrolled') {
        return course.isEnrolled == true;
      } else if (_filter == 'available') {
        return course.isEnrolled == false;
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
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search),
                    hintStyle: const TextStyle(color: Colors.black54),
                    prefixIconColor: Colors.black54,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[400], fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadCourses,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredCourses.isEmpty
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
                            onRefresh: _loadCourses,
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

  Widget _buildCourseCard(CourseBrowse course) {
    final isEnrolled = course.isEnrolled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/student/courses/${course.id}'),
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
                                course.title,
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
                          course.description ?? 'No description available',
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
                    course.teacherName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.studentsCount} students',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.description, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.contentCount} content',
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
                      context.push('/student/courses/${course.id}');
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

  Future<void> _enrollInCourse(CourseBrowse course) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll in Course'),
        content: Text('Are you sure you want to enroll in "${course.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _courseService.enrollInCourse(course.id);
                if (!mounted) return;
                setState(() {
                  _allCourses = _allCourses.map((item) {
                    if (item.id == course.id) {
                      return item.copyWith(
                        isEnrolled: true,
                        studentsCount: item.studentsCount + 1,
                      );
                    }
                    return item;
                  }).toList();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully enrolled in ${course.title}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }
}






