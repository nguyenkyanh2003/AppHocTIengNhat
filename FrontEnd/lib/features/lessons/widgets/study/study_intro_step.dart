import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/level_badge.dart';
import '../../models/lesson.dart';
import '../../models/lesson_study_step.dart';
import '../../models/situation_labels.dart';
import '../lesson_content_chips.dart';
import '../lesson_goals_card.dart';

/// Bước mở đầu: bài này nói về tình huống gì, học xong làm được gì, và mất
/// khoảng bao lâu — đủ để người học quyết định "được, học thôi".
class StudyIntroStep extends StatelessWidget {
  const StudyIntroStep({super.key, required this.detail});

  final LessonDetail detail;

  @override
  Widget build(BuildContext context) {
    final lesson = detail.lesson;
    final textTheme = Theme.of(context).textTheme;
    final situation = lesson.situation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (situation != null)
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.lesson.withValues(alpha: 0.12),
            child: Icon(situationIcon(situation), size: 36, color: AppColors.lesson),
          ),
        AppGap.lg,
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LevelBadge(lesson.level),
            Text('Khoảng ${estimateStudyMinutes(detail)} phút', style: textTheme.bodySmall),
          ],
        ),
        AppGap.sm,
        Text(
          lesson.displayTitle,
          style: AppTypography.heroDisplay(size: AppTypography.display, color: AppColors.textPrimary),
        ),
        if (lesson.description != null) ...[
          AppGap.sm,
          Text(lesson.description!, style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
        ],
        AppGap.lg,
        LessonContentChips(detail: detail),
        if (lesson.canDoGoals.isNotEmpty) ...[
          AppGap.xl,
          LessonGoalsCard(goals: lesson.canDoGoals),
        ],
      ],
    );
  }
}
