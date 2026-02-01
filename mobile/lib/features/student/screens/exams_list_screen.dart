import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../exams/models/exam_model.dart';
import '../services/course_service.dart';

class ExamsListScreen extends StatefulWidget {
  final String? courseId;
  const ExamsListScreen({super.key, this.courseId});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  late final StudentCourseService _courseService;
  List<StudentExamListItem> _exams = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _filter = 'all'; // 'all', 'available', 'in_progress', 'completed'

  @override
  void initState() {
    super.initState();
    _courseService = StudentCourseService(ApiClient());
    _loadExams();
  }

  Future<void> _loadExams() async {
    final cacheKey = 'cache:student:my_exams:${widget.courseId ?? 'all'}';
    var hadCache = false;

    final cached = await CacheService.getJson(cacheKey);
    if (cached is List) {
      final exams = cached
          .map((json) => StudentExamListItem.fromJson(json as Map<String, dynamic>))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      final inProgressIds = prefs.getStringList('in_progress_exams') ?? <String>[];
      final updated = exams.map((exam) {
        if (exam.status != 'completed' && inProgressIds.contains(exam.id.toString())) {
          return exam.copyWith(status: 'in_progress');
        }
        return exam;
      }).toList();

      hadCache = true;
      if (!mounted) return;
      setState(() {
        _exams = updated;
        _isLoading = false;
        _errorMessage = null;
      });
    }

    if (!hadCache && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final courseId = widget.courseId != null ? int.tryParse(widget.courseId!) : null;
      final exams = await _courseService.fetchMyExams(courseId: courseId);
      final prefs = await SharedPreferences.getInstance();
      final inProgressIds = prefs.getStringList('in_progress_exams') ?? <String>[];
      final updated = exams.map((exam) {
        if (exam.status != 'completed' && inProgressIds.contains(exam.id.toString())) {
          return exam.copyWith(status: 'in_progress');
        }
        return exam;
      }).toList();
      if (!mounted) return;
      setState(() {
        _exams = updated;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!hadCache) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = _exams.where((exam) {
      if (_filter == 'all') return true;
      return exam.status == _filter;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[400], fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadExams,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredExams.isEmpty
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

  Widget _buildExamCard(StudentExamListItem exam) {
    final status = exam.status;
    final score = exam.score;

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
            context.push('/student/exams/${exam.id}/take');
          } else if (status == 'completed') {
            context.push('/student/exams/${exam.id}/results');
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
                          exam.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.courseTitle,
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
                  Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${exam.questionsCount} questions',
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
                        'Score: ${score.toStringAsFixed(0)}%',
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
                      context.push('/student/exams/${exam.id}/take');
                    } else if (status == 'completed') {
                      context.push('/student/exams/${exam.id}/results');
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






