import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/exercise.dart';
import '../../../shared/widgets/level_badge.dart';

/// Một bài tập trong danh sách.
class ExerciseListCard extends StatelessWidget {
  const ExerciseListCard({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getTypeColor(exercise.type);
    final IconData typeIcon = _getTypeIcon(exercise.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.1),
            context.colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/exercise/${exercise.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'exercise_${exercise.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor.withValues(alpha: 0.7), typeColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(typeIcon, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: TextStyle(
                                fontSize: AppTypography.subtitle,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          LevelBadge(exercise.level),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (exercise.description != null &&
                          exercise.description!.isNotEmpty)
                        Text(
                          exercise.description!,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.quiz,
                            '${exercise.questionCount} câu',
                            AppColors.primary,
                          ),
                          if (exercise.timeLimit > 0)
                            _buildInfoChip(
                              context,
                              Icons.timer,
                              '${exercise.timeLimit} phút',
                              Colors.purple,
                            ),
                          _buildInfoChip(
                            context,
                            Icons.people,
                            '${exercise.totalAttempts} lượt',
                            AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.readable(color)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: context.colors.readable(color),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Từ vựng':
        return AppColors.primary;
      case 'Ngữ pháp':
        return AppColors.success;
      case 'Kanji':
        return AppColors.warning;
      case 'Tổng hợp':
        return Colors.purple;
      default:
        return AppColors.neutral;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Từ vựng':
        return Icons.spellcheck;
      case 'Ngữ pháp':
        return Icons.book;
      case 'Kanji':
        return Icons.text_fields;
      case 'Tổng hợp':
        return Icons.dashboard;
      default:
        return Icons.quiz;
    }
  }
}
