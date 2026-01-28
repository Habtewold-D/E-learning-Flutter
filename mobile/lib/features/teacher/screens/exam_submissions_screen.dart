import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ExamSubmissionsScreen extends StatefulWidget {
  final String examId;

  const ExamSubmissionsScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamSubmissionsScreen> createState() => _ExamSubmissionsScreenState();
}

class _ExamSubmissionsScreenState extends State<ExamSubmissionsScreen> {
  late final CourseService _courseService;
  List<ExamSubmission> _submissions = [];
  bool _isLoading = true;
  String? _error;

  int get _examId => int.tryParse(widget.examId) ?? 0;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissions = await _courseService.fetchExamSubmissions(_examId);
      setState(() {
        _submissions = submissions;
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
    final completedCount = _submissions.length;
    final averageScore = _submissions.isEmpty
        ? 0
        : _submissions.map((s) => s.score).fold(0.0, (a, b) => a + b) /
            _submissions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Submissions'),
        elevation: 0,
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
                        'Failed to load submissions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSubmissions,
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
                          _buildStatItem('Total', _submissions.length.toString(), Colors.white),
                          _buildStatItem('Completed', completedCount.toString(), Colors.green[100]!),
                          _buildStatItem('Avg Score', averageScore.toStringAsFixed(1), Colors.blue[100]!),
                        ],
                      ),
                    ),

                    if (_submissions.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No submissions yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _submissions.length,
                          itemBuilder: (context, index) {
                            final submission = _submissions[index];
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

  Widget _buildSubmissionCard(BuildContext context, ExamSubmission submission) {
    final percentage = submission.score.round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(percentage),
          child: Text(
            (submission.studentName.isNotEmpty ? submission.studentName : 'S')
                .substring(0, 1)
                .toUpperCase(),
            style: TextStyle(
              color: _getTextColor(percentage),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          submission.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(submission.studentEmail),
            const SizedBox(height: 4),
            Text(
              'Score: ${submission.correctAnswers}/${submission.totalQuestions} ($percentage%)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _getScoreColor(percentage),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing ${submission.studentName} submission (coming soon)')),
            );
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(int percentage) {
    if (percentage >= 80) return Colors.green[100]!;
    if (percentage >= 60) return Colors.orange[100]!;
    return Colors.red[100]!;
  }

  Color _getTextColor(int percentage) {
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

