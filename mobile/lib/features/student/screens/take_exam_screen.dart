import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class TakeExamScreen extends StatefulWidget {
  final String examId;
  const TakeExamScreen({super.key, required this.examId});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  late final StudentCourseService _courseService;
  ExamDetail? _exam;
  bool _isLoading = true;
  String? _error;

  int _currentQuestionIndex = 0;
  final Map<int, int?> _answers = {}; // question index -> selected option index
  int _timeRemaining = 0; // seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final examId = int.tryParse(widget.examId);
    if (examId == null) {
      setState(() {
        _error = 'Invalid exam id';
        _isLoading = false;
      });
      return;
    }

    try {
      final exam = await _courseService.fetchExamDetail(examId);
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _isLoading = false;
      });
      await _markInProgress(examId);
      _initializeTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markInProgress(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('in_progress_exams') ?? <String>[];
    if (!ids.contains(examId.toString())) {
      ids.add(examId.toString());
      await prefs.setStringList('in_progress_exams', ids);
    }
  }

  Future<void> _clearInProgress(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('in_progress_exams') ?? <String>[];
    ids.remove(examId.toString());
    await prefs.setStringList('in_progress_exams', ids);
  }

  void _initializeTimer() {
    final questionsCount = _exam?.questions.length ?? 0;
    _timeRemaining = questionsCount * 3 * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        _autoSubmit();
      }
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _autoSubmit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text('Your exam will be automatically submitted.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitExam() async {
    final examId = int.tryParse(widget.examId);
    if (examId == null || _exam == null) return;

    final answers = <int, String>{};
    for (int i = 0; i < _exam!.questions.length; i++) {
      final selectedIndex = _answers[i];
      if (selectedIndex == null) continue;
      answers[_exam!.questions[i].id] = _indexToOption(selectedIndex);
    }

    try {
      final result = await _courseService.submitExam(examId, answers);
      await _clearInProgress(examId);
      if (!mounted) return;
      final answersForReview = answers.map((key, value) => MapEntry(key.toString(), value));
      context.pushReplacement(
        '/student/exams/${widget.examId}/results',
        extra: {
          'result': result,
          'answers': answersForReview,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  String _indexToOption(int index) {
    switch (index) {
      case 0:
        return 'a';
      case 1:
        return 'b';
      case 2:
        return 'c';
      case 3:
        return 'd';
      default:
        return 'a';
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
        appBar: AppBar(title: const Text('Taking Exam')),
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
    final currentQuestion = questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    final options = [
      currentQuestion.optionA,
      currentQuestion.optionB,
      currentQuestion.optionC,
      currentQuestion.optionD,
    ].where((value) => value.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taking Exam'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining < 300 ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(_timeRemaining),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const StudentDrawer(),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: questions.isEmpty ? 0 : (_currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Submit Exam?'),
                        content: const Text('Are you sure you want to submit your exam?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _submitExam();
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQuestion.question,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ...options.asMap().entries.map((entry) {
                    final optionIndex = entry.key;
                    final optionText = entry.value;
                    final isSelected = _answers[_currentQuestionIndex] == optionIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[_currentQuestionIndex] = optionIndex;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: optionIndex,
                                groupValue: _answers[_currentQuestionIndex],
                                onChanged: (value) {
                                  setState(() {
                                    _answers[_currentQuestionIndex] = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (questions.isEmpty) return;
                      if (isLastQuestion) {
                        _submitExam();
                      } else {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      }
                    },
                    child: Text(isLastQuestion ? 'Submit Exam' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






