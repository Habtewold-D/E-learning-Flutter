import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/student_drawer.dart';

class ExamResultsScreen extends StatelessWidget {
  final String examId;
  final String? score;
  const ExamResultsScreen({super.key, required this.examId, this.score});

  @override
  Widget build(BuildContext context) {
    // Parse score from query parameter or use mock
    final int finalScore = score != null ? int.tryParse(score!) ?? 0 : 85;
    final int totalQuestions = 20;
    final int correctAnswers = ((finalScore / 100) * totalQuestions).round();

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
                      '$finalScore%',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review answers functionality coming soon!')),
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






