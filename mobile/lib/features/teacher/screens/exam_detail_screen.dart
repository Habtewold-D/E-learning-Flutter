import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ExamDetailScreen extends StatefulWidget {
  final String examId;

  const ExamDetailScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  late final CourseService _courseService;
  ExamDetail? _exam;
  List<ExamSubmission> _submissions = [];
  bool _isLoading = true;
  String? _error;

  int get _examId => int.tryParse(widget.examId) ?? 0;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    _fetchExamDetail();
  }

  Future<void> _fetchExamDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exam = await _courseService.fetchExamDetail(_examId);
      final submissions = await _courseService.fetchExamSubmissions(_examId);
      setState(() {
        _exam = exam;
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
    final exam = _exam;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam?.title ?? 'Exam Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: exam == null ? null : _showEditExamDialog,
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
                        'Failed to load exam',
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
                        onPressed: _fetchExamDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : exam == null
                  ? const Center(child: Text('Exam not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exam Info Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.title,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if ((exam.description ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      exam.description!,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        Icons.timer,
                                        '${_calculateDurationMinutes(exam.questions.length)} minutes',
                                      ),
                                      const SizedBox(width: 12),
                                      _buildInfoChip(
                                        Icons.quiz,
                                        '${exam.questions.length} question${exam.questions.length == 1 ? '' : 's'}',
                                      ),
                                      const SizedBox(width: 12),
                                      _buildInfoChip(
                                        Icons.people,
                                        '${_submissions.length} submission${_submissions.length == 1 ? '' : 's'}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Questions Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Questions (${exam.questions.length})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddQuestionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Question'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (exam.questions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No questions yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ...exam.questions.map((question) => _buildQuestionCard(question)),

                          const SizedBox(height: 24),

                          // Actions
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/teacher/exams/${widget.examId}/submissions');
                              },
                              icon: const Icon(Icons.people),
                              label: const Text('View Submissions'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  int _calculateDurationMinutes(int questionCount) {
    return questionCount * 3;
  }

  void _showEditExamDialog() {
    final exam = _exam;
    if (exam == null) return;

    final titleController = TextEditingController(text: exam.title);
    final descriptionController = TextEditingController(text: exam.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exam Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exam = ExamDetail(
                  id: exam.id,
                  courseId: exam.courseId,
                  title: titleController.text.trim().isEmpty
                      ? exam.title
                      : titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  questions: exam.questions,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => _ExamQuestionDialog(
        onSave: (question) {
          final exam = _exam;
          if (exam == null) return;

          final nextId = exam.questions.isEmpty
              ? 1
              : exam.questions.map((q) => q.id).fold(0, (a, b) => a > b ? a : b) + 1;

          final newQuestion = ExamQuestion(
            id: nextId,
            question: question.question,
            optionA: question.optionA,
            optionB: question.optionB,
            optionC: question.type == 'true_false' ? '' : question.optionC,
            optionD: question.type == 'true_false' ? '' : question.optionD,
            correctOption: question.correctOption,
          );

          setState(() {
            _exam = ExamDetail(
              id: exam.id,
              courseId: exam.courseId,
              title: exam.title,
              description: exam.description,
              questions: [...exam.questions, newQuestion],
            );
          });
        },
      ),
    );
  }

  Widget _buildQuestionCard(ExamQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    '${question.id}',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...[
              question.optionA,
              question.optionB,
              question.optionC,
              question.optionD,
            ].asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode('a'.codeUnitAt(0) + index);
              final isCorrect = optionLetter == question.correctOption.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green[50] : Colors.grey[50],
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCorrect ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option)),
                      if (isCorrect)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Correct',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ExamQuestionDraft {
  final String question;
  final String type;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;

  _ExamQuestionDraft({
    required this.question,
    required this.type,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
  });
}

class _ExamQuestionDialog extends StatefulWidget {
  final void Function(_ExamQuestionDraft) onSave;

  const _ExamQuestionDialog({required this.onSave});

  @override
  State<_ExamQuestionDialog> createState() => _ExamQuestionDialogState();
}

class _ExamQuestionDialogState extends State<_ExamQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  String _questionType = 'multiple_choice';
  String _correctOption = 'a';

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave(
      _ExamQuestionDraft(
        question: _questionController.text.trim(),
        type: _questionType,
        optionA: _optionAController.text.trim(),
        optionB: _optionBController.text.trim(),
        optionC: _questionType == 'true_false' ? '' : _optionCController.text.trim(),
        optionD: _questionType == 'true_false' ? '' : _optionDController.text.trim(),
        correctOption: _correctOption,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Question',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _questionType,
                  decoration: const InputDecoration(labelText: 'Question Type'),
                  items: const [
                    DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                    DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _questionType = value;
                      if (_questionType == 'true_false') {
                        _optionAController.text = 'True';
                        _optionBController.text = 'False';
                        _optionCController.clear();
                        _optionDController.clear();
                        _correctOption = 'a';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _optionAController,
                  decoration: const InputDecoration(labelText: 'Option A'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionBController,
                  decoration: const InputDecoration(labelText: 'Option B'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                if (_questionType == 'multiple_choice') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _optionCController,
                    decoration: const InputDecoration(labelText: 'Option C'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _optionDController,
                    decoration: const InputDecoration(labelText: 'Option D'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _correctOption,
                  decoration: const InputDecoration(labelText: 'Correct Option'),
                  items: _questionType == 'true_false'
                      ? const [
                          DropdownMenuItem(value: 'a', child: Text('True')),
                          DropdownMenuItem(value: 'b', child: Text('False')),
                        ]
                      : const [
                          DropdownMenuItem(value: 'a', child: Text('Option A')),
                          DropdownMenuItem(value: 'b', child: Text('Option B')),
                          DropdownMenuItem(value: 'c', child: Text('Option C')),
                          DropdownMenuItem(value: 'd', child: Text('Option D')),
                        ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _correctOption = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






