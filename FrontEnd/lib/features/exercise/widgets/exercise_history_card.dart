import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Một lần làm bài trong lịch sử.
class ExerciseHistoryCard extends StatelessWidget {
  const ExerciseHistoryCard({
    super.key,
    required this.result,
  });

  final ExerciseResult result;

  @override
  Widget build(BuildContext context) {
    final isPassed = result.passed;
    final score = result.score;

    // Get exercise info from the result
    String exerciseTitle = result.exerciseTitle ?? 'Bài tập đã hoàn thành';
    String exerciseLevel = result.exerciseLevel ?? '';
    String exerciseType = result.exerciseType ?? '';

    final completedAt = result.createdAt;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(completedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassed ? AppColors.success : context.colors.error,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Trước đây chỗ này chỉ nạp kết quả vào provider rồi dừng, vì chưa
          // có màn kết quả mở được bằng mã. Nay đã có đường dẫn thật.
          onTap: () => context.push('/exercise/result/${result.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppColors.successStrong
                            : AppColors.errorStrong,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${score.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.headline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseTitle,
                            style: const TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (exerciseLevel.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exerciseLevel,
                                    style: TextStyle(
                                      fontSize: AppTypography.caption,
                                      color: context.colors
                                          .readable(AppColors.warning),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (exerciseType.isNotEmpty)
                                Text(
                                  exerciseType,
                                  style: TextStyle(
                                    fontSize: AppTypography.caption,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.success : AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPassed ? 'Đạt' : 'Chưa đạt',
                        style: TextStyle(
                          color: isPassed
                              ? AppColors.success
                              : context.colors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStatChip(
                        context,
                        Icons.check_circle,
                        'Đúng',
                        '${result.correctAnswers}',
                        AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        context,
                        Icons.quiz,
                        'Tổng',
                        '${result.totalQuestions}',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        context,
                        Icons.timer,
                        'Thời gian',
                        _formatTime(result.timeSpent),
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: context.colors.textDisabled),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: context.colors.textDisabled,
                      ),
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

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.readable(color)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: FontWeight.bold,
                    color: context.colors.readable(color),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
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
