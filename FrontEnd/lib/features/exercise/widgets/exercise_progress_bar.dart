import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Số câu đã trả lời trên tổng số câu.
class ExerciseProgressBar extends StatelessWidget {
  const ExerciseProgressBar({
    super.key,
    required this.exercise,
    required this.userAnswers,
  });

  final Exercise exercise;
  final Map<String, String> userAnswers;

  @override
  Widget build(BuildContext context) {
    final answered = userAnswers.length;
    final total = exercise.questions.length;
    final progress = total > 0 ? answered / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answered/$total câu',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primaryStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
