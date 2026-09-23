import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_study_step.dart';
import '../study_step_icon.dart';

/// Đầu màn học: nút đóng, thanh tiến độ chia đoạn theo bước, và tên bước.
///
/// Mỗi đoạn là một bước thật của bài, nên người học thấy còn bao nhiêu việc
/// nhỏ chứ không phải một con số phần trăm trừu tượng.
class StudyProgressHeader extends StatelessWidget {
  const StudyProgressHeader({
    super.key,
    required this.steps,
    required this.index,
    required this.onClose,
  });

  final List<StudyStep> steps;
  final int index;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final step = steps[index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onClose, tooltip: 'Rời bài học', icon: const Icon(Icons.close)),
              AppGap.sm,
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      if (i > 0) AppGap.xs,
                      Expanded(
                        child: AnimatedContainer(
                          duration: reduceMotion ? Duration.zero : AppDurations.normal,
                          height: AppSpacing.md,
                          decoration: BoxDecoration(
                            color: i <= index ? AppColors.heroAction : AppColors.surfaceVariant,
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppGap.sm,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(studyStepIcon(step.kind), size: 18, color: AppColors.primary),
              AppGap.sm,
              Flexible(
                child: Text(
                  step.title,
                  style: textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
