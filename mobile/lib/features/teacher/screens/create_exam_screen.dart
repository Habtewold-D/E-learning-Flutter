import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class CreateExamScreen extends StatefulWidget {
  final String courseId;
  final String? examId; // For editing

  const CreateExamScreen({
    super.key,
    required this.courseId,
    this.examId,
  });

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;
  bool _isLoading = false;
  late final CourseService _courseService;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
    if (widget.examId != null) {
      _loadExamForEdit();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExamForEdit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final examId = int.tryParse(widget.examId ?? '');
      if (examId == null) return;

      final exam = await _courseService.fetchExamDetail(examId);
      _titleController.text = exam.title;
      _descriptionController.text = exam.description ?? '';

      _questions
        ..clear()
        ..addAll(exam.questions.map((q) {
          final options = [q.optionA, q.optionB, q.optionC, q.optionD];
          final correctIndex = ['a', 'b', 'c', 'd']
              .indexOf(q.correctOption.toLowerCase());
          return {
            'question': q.question,
            'type': 'multiple_choice',
            'options': options,
            'correct_answer': correctIndex >= 0 ? correctIndex : 0,
          };
        }));
    } catch (_) {
      // ignore load errors for now
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        onSave: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        question: _questions[index],
        onSave: (question) {
          setState(() {
            _questions[index] = question;
          });
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    var isSuccess = false;

    try {
      if (widget.examId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit exam is not supported yet.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final courseId = int.tryParse(widget.courseId);
        if (courseId == null) {
          throw Exception('Invalid course id');
        }

        final payloadQuestions = _questions.map((q) {
          final options = (q['options'] as List).map((o) => o.toString()).toList();
          final isTrueFalse = q['type'] == 'true_false';
          if (isTrueFalse && options.length >= 2) {
            while (options.length < 4) {
              options.add(options[options.length - 2]);
            }
          }
          while (options.length < 4) {
            options.add('');
          }
          final correctIndex = q['correct_answer'] as int;
          final correctOption = String.fromCharCode('a'.codeUnitAt(0) + correctIndex);
          return {
            'question': q['question'] as String,
            'option_a': options[0],
            'option_b': options[1],
            'option_c': options[2],
            'option_d': options[3],
            'correct_option': correctOption,
          };
        }).toList();

        await _courseService.createExam(
          courseId: courseId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          questions: payloadQuestions,
        );
        isSuccess = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (widget.examId == null && isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam created successfully!'),
            backgroundColor: Colors.lightBlue,
          ),
        );
        context.pop();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examId != null ? 'Edit Exam' : 'Create Exam'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        radius: 30,
                        child: Icon(
                          Icons.quiz,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.examId != null ? 'Edit Exam' : 'New Exam',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create questions for your exam',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Exam Title *',
                  hintText: 'e.g., Midterm Exam',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an exam title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Questions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions (${_questions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Questions List
              if (_questions.isEmpty)
                Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No questions yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Question'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return _buildQuestionCard(question, index);
                }),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.examId != null ? 'Update Exam' : 'Create Exam',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          question['question'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Type: ${question['type']} • Options: ${(question['options'] as List).length}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editQuestion(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _questions.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Question Dialog
class _QuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onSave;

  const _QuestionDialog({
    this.question,
    required this.onSave,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  String _questionType = 'multiple_choice';
  String _correctOption = 'a';

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!['question'] as String;
      _questionType = widget.question!['type'] as String;
      final options = widget.question!['options'] as List;
      final correctAnswer = widget.question!['correct_answer'] as int;
      _correctOption = String.fromCharCode('a'.codeUnitAt(0) + correctAnswer);

      _optionAController.text = options.isNotEmpty ? options[0].toString() : '';
      _optionBController.text = options.length > 1 ? options[1].toString() : '';
      _optionCController.text = options.length > 2 ? options[2].toString() : '';
      _optionDController.text = options.length > 3 ? options[3].toString() : '';
    }

    if (_questionType == 'true_false') {
      _optionAController.text = 'True';
      _optionBController.text = 'False';
      _optionCController.clear();
      _optionDController.clear();
      _correctOption = 'a';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = _questionType == 'true_false'
        ? [
            _optionAController.text.trim(),
            _optionBController.text.trim(),
          ]
        : [
            _optionAController.text.trim(),
            _optionBController.text.trim(),
            _optionCController.text.trim(),
            _optionDController.text.trim(),
          ];

    if (options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All options must be filled')),
      );
      return;
    }

    final correctAnswerIndex = _correctOption.codeUnitAt(0) - 'a'.codeUnitAt(0);

    widget.onSave({
      'question': _questionController.text.trim(),
      'type': _questionType,
      'options': options,
      'correct_answer': correctAnswerIndex,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.question != null ? 'Edit Question' : 'Add Question',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Question Type
                DropdownButtonFormField<String>(
                  value: _questionType,
                  decoration: InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                    DropdownMenuItem(value: 'true_false', child: Text('True/False')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _questionType = value!;
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
                const SizedBox(height: 16),

                // Question Text
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Question *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Options
                Text(
                  'Options *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionAController,
                  decoration: InputDecoration(
                    hintText: 'Option A',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionBController,
                  decoration: InputDecoration(
                    hintText: 'Option B',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                if (_questionType == 'multiple_choice') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _optionCController,
                    decoration: InputDecoration(
                      hintText: 'Option C',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _optionDController,
                    decoration: InputDecoration(
                      hintText: 'Option D',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
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
                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveQuestion,
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






