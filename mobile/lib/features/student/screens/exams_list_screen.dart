import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_drawer.dart';

class ExamsListScreen extends StatefulWidget {
  final String? courseId;
  const ExamsListScreen({super.key, this.courseId});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  // Mock exams data
  final List<Map<String, dynamic>> _exams = [
    {
      'id': 1,
      'title': 'Midterm Exam - Flutter Basics',
      'course': 'Introduction to Flutter',
      'duration': 60,
      'totalQuestions': 20,
      'status': 'available', // 'available', 'in_progress', 'completed'
      'score': null,
      'dueDate': '2024-12-30',
    },
    {
      'id': 2,
      'title': 'Final Exam - React Advanced',
      'course': 'Advanced React Development',
      'duration': 90,
      'totalQuestions': 30,
      'status': 'completed',
      'score': 85,
      'dueDate': '2024-12-25',
    },
    {
      'id': 3,
      'title': 'Quiz 1 - Python Basics',
      'course': 'Python Basics for Beginners',
      'duration': 30,
      'totalQuestions': 10,
      'status': 'in_progress',
      'score': null,
      'dueDate': '2024-12-28',
    },
  ];

  String _filter = 'all'; // 'all', 'available', 'in_progress', 'completed'

  @override
  Widget build(BuildContext context) {
    final filteredExams = _exams.where((exam) {
      if (widget.courseId != null) {
        // Filter by course if courseId is provided
        return exam['course'].toString().contains('Flutter'); // Mock filter
      }
      if (_filter == 'all') return true;
      return exam['status'] == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseId != null ? 'Course Exams' : 'My Exams'),
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
                    label: const Text('Available'),
                    selected: _filter == 'available',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'available');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('In Progress'),
                    selected: _filter == 'in_progress',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'in_progress');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Completed'),
                    selected: _filter == 'completed',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'completed');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Exams List
          Expanded(
            child: filteredExams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No exams found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
                      return _buildExamCard(exam);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final status = exam['status'] as String;
    final score = exam['score'] as int?;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'available':
        statusColor = Colors.blue;
        statusText = 'Available';
        statusIcon = Icons.quiz;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'In Progress';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (status == 'available' || status == 'in_progress') {
            context.push('/student/exams/${exam['id']}/take');
          } else if (status == 'completed') {
            context.push('/student/exams/${exam['id']}/results');
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
                          exam['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam['course'] as String,
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
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${exam['duration']} mins',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${exam['totalQuestions']} questions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (score != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Score: $score%',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (status == 'available' || status == 'in_progress') {
                      context.push('/student/exams/${exam['id']}/take');
                    } else if (status == 'completed') {
                      context.push('/student/exams/${exam['id']}/results');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    status == 'available'
                        ? 'Start Exam'
                        : status == 'in_progress'
                            ? 'Continue Exam'
                            : 'View Results',
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






