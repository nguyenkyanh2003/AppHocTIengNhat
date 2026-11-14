import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Điểm, số câu đúng và thời gian của một lần làm bài.
class ExerciseResultCard extends StatelessWidget {
  const ExerciseResultCard({
    super.key,
    required this.isPassed,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeSpent,
  });

  final bool isPassed;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int timeSpent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPassed ? AppColors.successStrong : AppColors.errorStrong,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.emoji_events : Icons.refresh,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Chúc mừng! Bạn đã đạt' : 'Chưa đạt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(0)} điểm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.check_circle,
                  'Đúng',
                  '$correctCount',
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatItem(
                  Icons.cancel,
                  'Sai',
                  '${totalQuestions - correctCount}',
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatItem(
                  Icons.timer,
                  'Thời gian',
                  _formatTime(timeSpent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.subtitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
