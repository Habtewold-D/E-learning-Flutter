import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final String examId;
  final Map<String, String>? answers; // questionId -> selected option (a/b/c/d)

  const ReviewAnswersScreen({
    super.key,
    required this.examId,
    this.answers,
  });

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  late final StudentCourseService _courseService;
  ExamDetail? _exam;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _loadExam();
  }

  Future<void> _loadExam() async {
    var hadCache = false;

    final examId = int.tryParse(widget.examId);
    if (examId == null) {
      setState(() {
        _error = 'Invalid exam id';
        _isLoading = false;
      });
      return;
    }

    final cached = await CacheService.getJson('cache:student:exam_detail:$examId');
    if (cached is Map<String, dynamic>) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        _exam = ExamDetail.fromJson(cached);
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
      final exam = await _courseService.fetchExamDetail(examId);
      if (!mounted) return;
      setState(() {
        _exam = exam;
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
        appBar: AppBar(title: const Text('Review Answers')),
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
                  onPressed: _loadExam,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _exam?.questions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final question = questions[index];
          final correct = question.correctOption.toLowerCase();
          final selected = widget.answers?[question.id.toString()]?.toLowerCase();

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}. ${question.question}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildOption(context, 'a', question.optionA, selected, correct),
                  _buildOption(context, 'b', question.optionB, selected, correct),
                  _buildOption(context, 'c', question.optionC, selected, correct),
                  _buildOption(context, 'd', question.optionD, selected, correct),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String key,
    String text,
    String? selected,
    String correct,
  ) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isCorrect = key == correct;
    final isSelected = selected == key;

    Color borderColor = Colors.grey[300]!;
    Color backgroundColor = Colors.transparent;

    if (isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (isSelected) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: borderColor,
            child: Text(
              key.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.green, size: 18)
          else if (isSelected)
            const Icon(Icons.cancel, color: Colors.red, size: 18),
        ],
      ),
    );
  }
}
