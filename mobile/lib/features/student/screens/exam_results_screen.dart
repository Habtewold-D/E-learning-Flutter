import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ExamResultsScreen extends StatefulWidget {
  final String examId;
  final String? score;
  final ExamResult? result;
  final Map<String, String>? answers;
  const ExamResultsScreen({
    super.key,
    required this.examId,
    this.score,
    this.result,
    this.answers,
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  late final StudentCourseService _courseService;
  ExamResult? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _result = widget.result as ExamResult?;
    if (_result == null) {
      _loadResult();
    }
  }

  Future<void> _loadResult() async {
    var hadCache = false;

    final examId = int.tryParse(widget.examId);
    if (examId == null) {
      setState(() {
        _error = 'Invalid exam id';
        _isLoading = false;
      });
      return;
    }

    final cached = await CacheService.getJson('cache:student:exam_result:$examId');
    if (cached is Map<String, dynamic>) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        _result = ExamResult.fromJson(cached);
        _isLoading = false;
        _error = null;
      });
    }

    if (!hadCache && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await _courseService.fetchMyExamResult(examId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!hadCache) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Results'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadResult,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final parsedScore = widget.score != null ? double.tryParse(widget.score!) : null;
    final double finalScore = _result?.score ?? parsedScore ?? 0;
    final int totalQuestions = _result?.totalQuestions ?? 0;
    final int correctAnswers = _result?.correctAnswers ?? ((finalScore / 100) * totalQuestions).round();

    Color scoreColor;
    String scoreMessage;
    IconData scoreIcon;

    if (finalScore >= 80) {
      scoreColor = Colors.green;
      scoreMessage = 'Excellent!';
      scoreIcon = Icons.celebration;
    } else if (finalScore >= 60) {
      scoreColor = Colors.orange;
      scoreMessage = 'Good job!';
      scoreIcon = Icons.thumb_up;
    } else {
      scoreColor = Colors.red;
      scoreMessage = 'Keep practicing!';
      scoreIcon = Icons.trending_up;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Score Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      scoreColor,
                      scoreColor.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(scoreIcon, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      '${finalScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreMessage,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$correctAnswers out of $totalQuestions correct',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.check_circle,
                    label: 'Correct',
                    value: correctAnswers.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.cancel,
                    label: 'Incorrect',
                    value: (totalQuestions - correctAnswers).toString(),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.help_outline,
                    label: 'Total',
                    value: totalQuestions.toString(),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/student/exams'),
                icon: const Icon(Icons.list),
                label: const Text('Back to Exams'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/student/exams/${widget.examId}/review',
                    extra: {
                      'answers': widget.answers,
                    },
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Review Answers'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
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
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}






