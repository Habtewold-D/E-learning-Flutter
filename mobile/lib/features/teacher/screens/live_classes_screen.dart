import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../../core/api/api_client.dart';
import '../services/live_class_service.dart';
import '../services/course_service.dart';
import '../models/live_class.dart';
import '../../courses/models/course_model.dart';

class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  late final LiveClassService _liveClassService;
  late final CourseService _courseService;

  List<LiveClass> _liveClasses = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _liveClassService = LiveClassService(ApiClient());
    _courseService = CourseService(ApiClient());
    _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _endTimeText(LiveClass liveClass, DateFormat formatter) {
    final base = liveClass.startedAt ?? liveClass.scheduledTime;
    if (base == null) {
      return 'Ends ~1h after start';
    }
    final end = base.add(const Duration(hours: 1));
    return 'Will end by ${formatter.format(end)} (max 1h)';
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _liveClassService.fetchLiveClasses(),
        _courseService.fetchCourses(),
      ]);

      setState(() {
        _liveClasses = results[0] as List<LiveClass>;
        _courses = results[1] as List<Course>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _liveClasses.where((c) => c.isActive).length;
    final scheduledCount = _liveClasses.where((c) => c.isScheduled).length;
    final endedCount = _liveClasses.where((c) => c.isEnded).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateClassDialog(context),
            tooltip: 'Create Live Class',
          ),
        ],
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
                        'Failed to load live classes',
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
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Active', activeCount, Colors.green, () => _setFilter('active')),
                          _buildStatItem('Scheduled', scheduledCount, Colors.blue, () => _setFilter('scheduled')),
                          _buildStatItem('Ended', endedCount, Colors.grey, () => _setFilter('ended')),
                          _buildStatItem('Total', _liveClasses.length, Colors.white, () => _setFilter('all')),
                        ],
                      ),
                    ),

                    // Classes List
                    Expanded(
                      child: _liveClasses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_call_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No live classes yet',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showCreateClassDialog(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create First Live Class'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredClasses().length,
                                itemBuilder: (context, index) {
                                  final liveClass = _filteredClasses()[index];
                                  return _buildLiveClassCard(liveClass);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: const TeacherBottomNav(currentIndex: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        icon: const Icon(Icons.video_call),
        label: const Text('Create Class'),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveClassCard(LiveClass liveClass) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final course = _courses.firstWhere(
      (c) => c.id == liveClass.courseId,
      orElse: () => Course(
        id: liveClass.courseId,
        title: 'Unknown Course',
        description: '',
        teacherId: 0,
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: liveClass.isActive || liveClass.isScheduled
            ? () => _joinClass(liveClass)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: liveClass.isActive
                          ? Colors.green[100]
                          : liveClass.isScheduled
                              ? Colors.blue[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      liveClass.statusDisplay.toUpperCase(),
                      style: TextStyle(
                        color: liveClass.isActive
                            ? Colors.green[800]
                            : liveClass.isScheduled
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (liveClass.isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      liveClass.isActive
                          ? 'Started: ${liveClass.startedAt != null ? formatter.format(liveClass.startedAt!) : "-"}'
                          : liveClass.isScheduled
                              ? 'Scheduled: ${liveClass.scheduledTime != null ? formatter.format(liveClass.scheduledTime!) : "-"}'
                              : 'Ended: ${liveClass.endedAt != null ? formatter.format(liveClass.endedAt!) : "-"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (liveClass.startedAt != null || liveClass.scheduledTime != null)
                Text(
                  _endTimeText(liveClass, formatter),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              if (liveClass.isActive || liveClass.isScheduled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: liveClass.isActive ? () => _joinClass(liveClass) : () => _startClass(liveClass),
                    icon: Icon(liveClass.isActive ? Icons.video_call : Icons.schedule),
                    label: Text(liveClass.isActive ? 'Join Class' : 'Start Class'),
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
      ),
    );
  }

  List<LiveClass> _filteredClasses() {
    switch (_filter) {
      case 'active':
        return _liveClasses.where((c) => c.isActive).toList();
      case 'scheduled':
        return _liveClasses.where((c) => c.isScheduled).toList();
      case 'ended':
        return _liveClasses.where((c) => c.isEnded).toList();
      default:
        return _liveClasses;
    }
  }

  Future<void> _startClass(LiveClass liveClass) async {
    try {
      final updated = await _liveClassService.startLiveClass(liveClass.id);
      await _refreshData();
      // navigate to join screen
      context.push('/teacher/live/${updated.roomName}?classId=${updated.id}');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _joinClass(LiveClass liveClass) async {
    // navigate to join screen which opens Jitsi URL
    context.push('/teacher/live/${liveClass.roomName}?classId=${liveClass.id}');
  }

  void _showCreateClassDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTime? selectedDateTime;
    Course? selectedCourse;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Live Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Course Selection
                DropdownButtonFormField<Course>(
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCourse,
                  items: _courses.map((course) => DropdownMenuItem(
                    value: course,
                    child: Text(course.title),
                  )).toList(),
                  onChanged: (course) => setState(() => selectedCourse = course),
                ),
                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Class Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter a descriptive title for the live class',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Title is required';
                    if (value!.length < 3) return 'Title must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Scheduled Time (Optional)
                ListTile(
                  title: Text(selectedDateTime == null
                    ? 'Start immediately'
                    : 'Scheduled: ${selectedDateTime!.toLocal().toString().substring(0, 16)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => selectedDateTime = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute
                          ));
                        }
                      }
                    },
                  ),
                  subtitle: const Text('Optional - leave empty to start now'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCourse == null || titleController.text.trim().isEmpty
                ? null
                : () => _createLiveClass(selectedCourse!, titleController.text.trim(), selectedDateTime),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createLiveClass(Course course, String title, DateTime? scheduledTime) async {
    Navigator.pop(context); // Close dialog

    try {
      await _liveClassService.createLiveClass(
        courseId: course.id,
        title: title,
        scheduledTime: scheduledTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live class "${title}" created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _refreshData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create live class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}






