import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';

/// Màn giới thiệu trước khi bắt đầu làm bài.
class ExerciseStartView extends StatelessWidget {
  const ExerciseStartView({
    super.key,
    required this.exercise,
    required this.startExercise,
  });

  final Exercise exercise;
  final VoidCallback startExercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                LevelBadge(exercise.level),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    exercise.type,
                                    style: TextStyle(
                                      color: context.colors.primaryStrong,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              exercise.title,
                              style: TextStyle(
                                fontSize: AppTypography.headline,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            if (exercise.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  exercise.description!,
                                  style: TextStyle(
                                    fontSize: AppTypography.body,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            _buildInfoRow(
                              context,
                              Icons.quiz,
                              'Số câu hỏi',
                              '${exercise.questions.length} câu',
                              AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            if (exercise.timeLimit > 0)
                              _buildInfoRow(
                                context,
                                Icons.timer,
                                'Thời gian',
                                '${exercise.timeLimit} phút',
                                AppColors.warning,
                              ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              Icons.check_circle,
                              'Điểm đạt',
                              '${exercise.passScore}%',
                              AppColors.success,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: startExercise,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Bắt đầu làm bài',
                                  style: TextStyle(
                                    fontSize: AppTypography.subtitle,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.readable(color), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
