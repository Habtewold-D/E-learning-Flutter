import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../courses/models/course_model.dart';
import '../../teacher/models/live_class.dart';
import '../../teacher/services/course_service.dart';
import '../services/live_class_service.dart';

class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
  late final StudentLiveClassService _liveClassService;
  late final CourseService _courseService;

  List<LiveClass> _liveClasses = [];
  List<Course> _courses = [];
  String _filter = 'all'; // 'all', 'upcoming', 'live', 'ended'
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _liveClassService = StudentLiveClassService(ApiClient());
    _courseService = CourseService(ApiClient());
    _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final liveClasses = await _liveClassService.fetchLiveClasses();
      final courses = await _courseService.fetchCourses();

      setState(() {
        _liveClasses = liveClasses;
        _courses = courses;
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
    final filteredClasses = _liveClasses.where((liveClass) {
      if (_filter == 'all') return true;
      if (_filter == 'live') return liveClass.status == 'active';
      if (_filter == 'upcoming') return liveClass.status == 'scheduled';
      if (_filter == 'ended') return liveClass.status == 'ended';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load live classes',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _filter == 'all',
                            onSelected: (selected) => setState(() => _filter = 'all'),
                          ),
                          ChoiceChip(
                            label: const Text('Upcoming'),
                            selected: _filter == 'upcoming',
                            onSelected: (selected) => setState(() => _filter = 'upcoming'),
                          ),
                          ChoiceChip(
                            label: const Text('Live'),
                            selected: _filter == 'live',
                            onSelected: (selected) => setState(() => _filter = 'live'),
                          ),
                          ChoiceChip(
                            label: const Text('Ended'),
                            selected: _filter == 'ended',
                            onSelected: (selected) => setState(() => _filter = 'ended'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredClasses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_call_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No live classes found',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredClasses.length,
                                itemBuilder: (context, index) {
                                  final liveClass = filteredClasses[index];
                                  return _buildLiveClassCard(liveClass);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLiveClassCard(LiveClass liveClass) {
    final status = liveClass.status;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        statusText = 'Upcoming';
        statusIcon = Icons.schedule;
        break;
      case 'active':
        statusColor = Colors.red;
        statusText = 'Live Now';
        statusIcon = Icons.videocam;
        break;
      case 'ended':
        statusColor = Colors.grey;
        statusText = 'Ended';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    final course = _courses.firstWhere(
      (c) => c.id == liveClass.courseId,
      orElse: () => Course(
        id: liveClass.courseId,
        title: 'Course #${liveClass.courseId}',
        description: '',
        teacherId: liveClass.teacherId,
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: status == 'active' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: status == 'live'
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (status == 'active' || status == 'scheduled') {
            _handleJoin(liveClass);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This live class has ended')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveClass.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.title,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Course ID: ${liveClass.courseId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _buildTimeText(liveClass),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _endTimeText(liveClass),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (status == 'active' || status == 'scheduled')
                      ? () => _handleJoin(liveClass)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'active' ? Colors.red : statusColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    status == 'active'
                        ? 'Join Now'
                        : status == 'scheduled'
                            ? 'Join When Live'
                            : 'Class Ended',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeText(LiveClass liveClass) {
    if (liveClass.status == 'active' && liveClass.startedAt != null) {
      return 'Started: ${liveClass.startedAt!.toLocal()}';
    }
    if (liveClass.status == 'scheduled' && liveClass.scheduledTime != null) {
      return 'Starts: ${liveClass.scheduledTime!.toLocal()}';
    }
    if (liveClass.endedAt != null) {
      return 'Ended: ${liveClass.endedAt!.toLocal()}';
    }
    return 'Time not set';
  }

  String _endTimeText(LiveClass liveClass) {
    final base = liveClass.startedAt ?? liveClass.scheduledTime;
    if (base == null) return 'Ends ~1h after start';
    final end = base.add(const Duration(hours: 1));
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return 'Will end by ${formatter.format(end)} (max 1h)';
  }

  Future<void> _handleJoin(LiveClass liveClass) async {
    try {
      final joined = await _liveClassService.joinLiveClass(liveClass.id);
      if (!mounted) return;
      context.push('/student/live/${joined.roomName}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}






