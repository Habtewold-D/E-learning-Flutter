import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/teacher_drawer.dart';

class ExamSubmissionsScreen extends StatelessWidget {
  final String examId;

  const ExamSubmissionsScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock submissions data
    final submissions = [
      {
        'id': 1,
        'studentName': 'John Doe',
        'studentEmail': 'john@example.com',
        'score': 85,
        'totalQuestions': 20,
        'submittedAt': '2024-12-23 10:30',
        'status': 'completed',
      },
      {
        'id': 2,
        'studentName': 'Jane Smith',
        'studentEmail': 'jane@example.com',
        'score': 92,
        'totalQuestions': 20,
        'submittedAt': '2024-12-23 11:15',
        'status': 'completed',
      },
      {
        'id': 3,
        'studentName': 'Bob Johnson',
        'studentEmail': 'bob@example.com',
        'score': 78,
        'totalQuestions': 20,
        'submittedAt': '2024-12-23 12:00',
        'status': 'completed',
      },
      {
        'id': 4,
        'studentName': 'Alice Williams',
        'studentEmail': 'alice@example.com',
        'score': 0,
        'totalQuestions': 20,
        'submittedAt': null,
        'status': 'in_progress',
      },
    ];

    final completedCount = submissions.where((s) => s['status'] == 'completed').length;
    final averageScore = submissions
            .where((s) => s['status'] == 'completed')
            .map((s) => s['score'] as int)
            .fold(0, (a, b) => a + b) /
        (completedCount > 0 ? completedCount : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Submissions'),
        elevation: 0,
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
                _buildStatItem('Total', submissions.length.toString(), Colors.white),
                _buildStatItem('Completed', completedCount.toString(), Colors.green[100]!),
                _buildStatItem('Avg Score', averageScore.toStringAsFixed(1), Colors.blue[100]!),
              ],
            ),
          ),

          // Submissions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return _buildSubmissionCard(context, submission);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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

  Widget _buildSubmissionCard(BuildContext context, Map<String, dynamic> submission) {
    final isCompleted = submission['status'] == 'completed';
    final score = submission['score'] as int;
    final percentage = (score / (submission['totalQuestions'] as int) * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(isCompleted, percentage),
          child: Text(
            submission['studentName'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: _getTextColor(isCompleted, percentage),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          submission['studentName'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(submission['studentEmail'] as String),
            const SizedBox(height: 4),
            if (isCompleted) ...[
              Text(
                'Score: $score/${submission['totalQuestions']} ($percentage%)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _getScoreColor(percentage),
                ),
              ),
              Text(
                'Submitted: ${submission['submittedAt']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'In Progress',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: isCompleted
            ? IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  // View submission details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing ${submission['studentName']} submission (coming soon)')),
                  );
                },
              )
            : null,
      ),
    );
  }

  Color _getAvatarColor(bool isCompleted, int percentage) {
    if (!isCompleted) return Colors.grey[200]!;
    if (percentage >= 80) return Colors.green[100]!;
    if (percentage >= 60) return Colors.orange[100]!;
    return Colors.red[100]!;
  }

  Color _getTextColor(bool isCompleted, int percentage) {
    if (!isCompleted) return Colors.grey[800]!;
    if (percentage >= 80) return Colors.green[800]!;
    if (percentage >= 60) return Colors.orange[800]!;
    return Colors.red[800]!;
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}

