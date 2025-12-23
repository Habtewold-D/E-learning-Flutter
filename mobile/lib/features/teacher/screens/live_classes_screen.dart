import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_bottom_nav.dart';
import '../../../core/widgets/teacher_drawer.dart';

class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  // Mock live classes data
  final List<Map<String, dynamic>> _liveClasses = [
    {
      'id': 1,
      'courseName': 'Introduction to Flutter',
      'roomName': 'course-1-abc123',
      'roomUrl': 'https://meet.jit.si/course-1-abc123',
      'status': 'active',
      'participants': 8,
      'startedAt': '2024-12-23 10:00',
    },
    {
      'id': 2,
      'courseName': 'Advanced React Development',
      'roomName': 'course-2-xyz789',
      'roomUrl': 'https://meet.jit.si/course-2-xyz789',
      'status': 'scheduled',
      'participants': 0,
      'scheduledAt': '2024-12-24 14:00',
    },
    {
      'id': 3,
      'courseName': 'Python Basics',
      'roomName': 'course-3-def456',
      'roomUrl': 'https://meet.jit.si/course-3-def456',
      'status': 'ended',
      'participants': 0,
      'endedAt': '2024-12-22 16:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
      body: Column(
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
                _buildStatItem('Active', _liveClasses.where((c) => c['status'] == 'active').length, Colors.green),
                _buildStatItem('Scheduled', _liveClasses.where((c) => c['status'] == 'scheduled').length, Colors.blue),
                _buildStatItem('Total', _liveClasses.length, Colors.white),
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
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _liveClasses.length,
                      itemBuilder: (context, index) {
                        final liveClass = _liveClasses[index];
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

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
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
    );
  }

  Widget _buildLiveClassCard(Map<String, dynamic> liveClass) {
    final status = liveClass['status'] as String;
    final isActive = status == 'active';
    final isScheduled = status == 'scheduled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isActive || isScheduled
            ? () => context.push('/teacher/live/${liveClass['roomName']}')
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
                      color: isActive
                          ? Colors.green[100]
                          : isScheduled
                              ? Colors.blue[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? Colors.green[800]
                            : isScheduled
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
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
                liveClass['courseName'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${liveClass['participants']} participants',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    isActive
                        ? 'Started: ${liveClass['startedAt']}'
                        : isScheduled
                            ? 'Scheduled: ${liveClass['scheduledAt']}'
                            : 'Ended: ${liveClass['endedAt']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (isActive || isScheduled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/teacher/live/${liveClass['roomName']}'),
                    icon: Icon(isActive ? Icons.video_call : Icons.schedule),
                    label: Text(isActive ? 'Join Class' : 'Start Class'),
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

  void _showCreateClassDialog(BuildContext context) {
    // Mock courses for selection
    final courses = [
      'Introduction to Flutter',
      'Advanced React Development',
      'Python Basics for Beginners',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Live Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a course:'),
            const SizedBox(height: 16),
            ...courses.map((course) => ListTile(
                  title: Text(course),
                  onTap: () {
                    Navigator.pop(context);
                    // Create live class (mock)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Live class created for $course'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

