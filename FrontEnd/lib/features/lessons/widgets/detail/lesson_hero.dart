import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/level_badge.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../models/lesson_study_step.dart';
import '../../models/situation_labels.dart';
import '../lesson_content_chips.dart';

/// Phần đầu màn bài học: tình huống, tên bài, mô tả, bài có gì và đã học tới
/// đâu. Không còn banner trống cao 200px — thông tin người học cần nằm ngay
/// trong màn hình đầu tiên.
class LessonHero extends StatelessWidget {
  const LessonHero({super.key, required this.detail, required this.progress});

  final LessonDetail detail;
  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final lesson = detail.lesson;
    final textTheme = Theme.of(context).textTheme;
    final situation = lesson.situation;
    final percent = progress == null ? 0.0 : progress!.overallProgress;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  LevelBadge(lesson.level),
                  if (situation != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(situationIcon(situation),
                            size: 16,
                            color: context.colors.readable(AppColors.lesson)),
                        AppGap.xs,
                        Flexible(
                            child: Text(situationLabel(situation),
                                style: textTheme.labelLarge?.copyWith(
                                    color: context.colors
                                        .readable(AppColors.lesson)))),
                      ],
                    ),
                  Text('Khoảng ${estimateStudyMinutes(detail)} phút',
                      style: textTheme.bodySmall),
                ],
              ),
              AppGap.sm,
              Text(
                lesson.displayTitle,
                style: AppTypography.heroDisplay(
                    size: AppTypography.display,
                    color: context.colors.textPrimary),
              ),
              if (lesson.description != null) ...[
                AppGap.sm,
                Text(lesson.description!,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: context.colors.textSecondary)),
              ],
              AppGap.lg,
              LessonContentChips(detail: detail),
            ],
          ),
        ),
        AppGap.lg,
        _ProgressRing(
            value: percent, completed: progress?.isCompleted ?? false),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.completed});

  final double value;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.primary;
    return Semantics(
      label: completed ? 'Đã hoàn thành' : 'Đã học ${(value * 100).round()}%',
      child: SizedBox.square(
        dimension: 84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: completed ? 1 : value,
              strokeWidth: 8,
              backgroundColor: context.colors.surfaceVariant,
              color: context.colors.readable(color),
            ),
            Center(
              child: completed
                  ? Icon(Icons.check_rounded,
                      size: 40,
                      color: context.colors.readable(AppColors.success))
                  : Text('${(value * 100).round()}%',
                      style: AppTypography.heroDisplay(
                          size: AppTypography.subtitle,
                          color: context.colors.readable(color))),
            ),
          ],
        ),
      ),
    );
  }
}
