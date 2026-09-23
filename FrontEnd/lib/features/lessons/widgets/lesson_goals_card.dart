import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// "Sau bài này bạn làm được": mục tiêu viết theo việc làm được ngoài đời,
/// không theo số từ phải thuộc — lý do để người học muốn học tiếp.
class LessonGoalsCard extends StatelessWidget {
  const LessonGoalsCard({super.key, required this.goals});

  final List<String> goals;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 20, color: AppColors.success),
              AppGap.sm,
              Text(
                'Sau bài này bạn làm được',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppGap.md,
          for (final goal in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                  AppGap.sm,
                  Expanded(child: Text(goal, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
