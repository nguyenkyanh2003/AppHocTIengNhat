import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/day_key.dart';
import '../models/user_streak.dart';

/// Tiến độ mục tiêu XP của hôm nay.
///
/// Mục tiêu tách khỏi chuỗi (spec §5.1): chưa đạt mục tiêu mà đã học thì chuỗi
/// vẫn giữ, nên thẻ nói rõ điều đó để người học không tưởng mình bị phạt.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.goal, required this.onEdit});

  final DailyGoalProgress goal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    final color = goal.reached ? AppColors.success : AppColors.heroAction;

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: color),
                AppGap.sm,
                Expanded(child: Text('Mục tiêu hôm nay', style: theme.textTheme.titleMedium)),
                TextButton(onPressed: onEdit, child: const Text('Đổi mục tiêu')),
              ],
            ),
            AppGap.sm,
            Text(
              '${goal.todayXp}/${goal.targetXp} XP',
              style: AppTypography.heroDisplay(size: AppTypography.title, color: color),
            ),
            AppGap.sm,
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: goal.ratio,
                minHeight: AppSpacing.sm,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
                semanticsLabel: 'Tiến độ mục tiêu hôm nay',
              ),
            ),
            AppGap.sm,
            Text(
              goal.reached
                  ? 'Đã đạt mục tiêu hôm nay 🎉'
                  : 'Còn ${goal.remainingXp} XP nữa để đạt mục tiêu.',
              style: theme.textTheme.bodyMedium,
            ),
            if (goal.nextTargetXp != null && goal.nextTargetFrom != null) ...[
              AppGap.xs,
              Text(
                'Từ ${formatDayKey(goal.nextTargetFrom!)}: mục tiêu ${goal.nextTargetXp} XP.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            AppGap.xs,
            Text(
              'Chỉ tính XP từ hoạt động học. Mục tiêu không ảnh hưởng chuỗi ngày.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
