import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/learning_goal.dart';

String formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

/// Một mục tiêu: tiến độ, phần còn lại, hạn và lối vào hoạt động học làm tăng
/// tiến độ (thay cho nút "+1" của bản mẫu cũ).
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.now,
    required this.onStudy,
    required this.onEdit,
    required this.onDelete,
  });

  final LearningGoal goal;
  final DateTime now;
  final VoidCallback onStudy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unit = goal.type.unit;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(goal.type.label, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Sửa mục tiêu', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
                IconButton(tooltip: 'Xoá mục tiêu', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
              ],
            ),
            AppGap.md,
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                color: goal.isCompleted ? AppColors.success : null,
              ),
            ),
            AppGap.sm,
            // Màn hẹp không đủ chỗ cho cả số lẫn hạn trên một dòng: hạn xuống dòng.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    '${goal.current}/${goal.target} $unit',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  _Status(goal: goal, now: now),
                ],
              ),
            ),
            if (!goal.isCompleted) ...[
              Text('Còn ${goal.remaining} $unit', style: textTheme.bodySmall),
              AppGap.sm,
              Text(goal.type.howTo, style: textTheme.bodySmall),
              AppGap.md,
              FilledButton.tonalIcon(
                onPressed: onStudy,
                icon: const Icon(Icons.arrow_forward),
                label: Text(goal.type.studyLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.goal, required this.now});

  final LearningGoal goal;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final completedAt = goal.completedAt;
    final deadline = goal.deadline;

    if (goal.isCompleted) {
      return Text(
        completedAt == null ? 'Hoàn thành' : 'Hoàn thành ${formatDate(completedAt.toLocal())}',
        style: style?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
      );
    }
    if (goal.isOverdue(now)) {
      return Text('Quá hạn', style: style?.copyWith(color: context.colors.error, fontWeight: FontWeight.bold));
    }
    if (deadline == null) return const SizedBox.shrink();

    final daysLeft = deadline.difference(DateTime(now.year, now.month, now.day)).inDays;
    return Text(
      daysLeft == 0 ? 'Hạn hôm nay' : 'Hạn ${formatDate(deadline)} · còn $daysLeft ngày',
      style: style,
    );
  }
}
