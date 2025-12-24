import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_drawer.dart';

class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
  // Mock live classes
  final List<Map<String, dynamic>> _liveClasses = [
    {
      'id': 1,
      'title': 'Live Q&A: Flutter Basics',
      'course': 'Introduction to Flutter',
      'teacher': 'John Teacher',
      'date': '2024-12-25',
      'time': '10:00 AM',
      'status': 'upcoming', // 'upcoming', 'live', 'ended'
      'roomName': 'flutter-basics-qa',
    },
    {
      'id': 2,
      'title': 'Workshop: React Hooks',
      'course': 'Advanced React Development',
      'teacher': 'Jane Instructor',
      'date': '2024-12-24',
      'time': '02:00 PM',
      'status': 'live',
      'roomName': 'react-hooks-workshop',
    },
    {
      'id': 3,
      'title': 'Python Review Session',
      'course': 'Python Basics for Beginners',
      'teacher': 'Bob Teacher',
      'date': '2024-12-23',
      'time': '11:00 AM',
      'status': 'ended',
      'roomName': 'python-review',
    },
  ];

  String _filter = 'all'; // 'all', 'upcoming', 'live', 'ended'

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _liveClasses.where((liveClass) {
      if (_filter == 'all') return true;
      return liveClass['status'] == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                    label: const Text('Upcoming'),
                    selected: _filter == 'upcoming',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'upcoming');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Live'),
                    selected: _filter == 'live',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'live');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Ended'),
                    selected: _filter == 'ended',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'ended');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Live Classes List
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
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
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

  Widget _buildLiveClassCard(Map<String, dynamic> liveClass) {
    final status = liveClass['status'] as String;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'upcoming':
        statusColor = Colors.blue;
        statusText = 'Upcoming';
        statusIcon = Icons.schedule;
        break;
      case 'live':
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: status == 'live' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: status == 'live'
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (status == 'live' || status == 'upcoming') {
            context.push('/student/live/${liveClass['roomName']}');
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
                          liveClass['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          liveClass['course'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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
                  Text(
                    'Teacher: ${liveClass['teacher']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${liveClass['date']} at ${liveClass['time']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (status == 'live' || status == 'upcoming') {
                      context.push('/student/live/${liveClass['roomName']}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This live class has ended')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'live' ? Colors.red : statusColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    status == 'live'
                        ? 'Join Now'
                        : status == 'upcoming'
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
}


