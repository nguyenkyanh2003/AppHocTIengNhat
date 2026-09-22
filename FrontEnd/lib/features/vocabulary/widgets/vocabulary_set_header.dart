import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/chunky_card.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/vocabulary_set.dart';

/// Đầu màn một bộ từ vựng: cấp, tiến độ, nút học và các nút đánh dấu.
class VocabularySetHeader extends StatelessWidget {
  const VocabularySetHeader({
    super.key,
    required this.set,
    required this.isMarking,
    required this.onStudy,
    required this.onMarkAllLearned,
    required this.onUnmarkAll,
  });

  final VocabularySet set;
  final bool isMarking;
  final VoidCallback onStudy;
  final VoidCallback onMarkAllLearned;
  final VoidCallback onUnmarkAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = set.isCompleted;
    final barColor = done ? AppColors.success : AppColors.accent;

    return ChunkyCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelBadge(set.level),
              if (set.section != null) ...[
                AppGap.sm,
                Text(set.section!, style: textTheme.labelLarge),
              ],
              const Spacer(),
              Text(
                '${set.learnedCount}/${set.wordCount}',
                style: textTheme.titleLarge?.copyWith(color: barColor),
              ),
            ],
          ),
          AppGap.md,
          Text(
            done
                ? 'Tuyệt vời! Bạn đã học hết bộ này 🎉'
                : set.learnedCount == 0
                    ? 'Bắt đầu với ${set.wordCount} từ mới'
                    : 'Còn ${set.wordCount - set.learnedCount} từ chưa học',
            style: textTheme.titleMedium,
          ),
          AppGap.sm,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: set.progress,
              minHeight: AppSpacing.md,
              color: barColor,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          AppGap.xl,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStudy,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              icon: const Icon(Icons.style_rounded),
              label:
                  Text(done ? 'Ôn lại bằng flashcard' : 'Học bằng flashcard'),
            ),
          ),
          AppGap.md,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!done)
                OutlinedButton.icon(
                  onPressed: isMarking ? null : onMarkAllLearned,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Đã thuộc cả bộ'),
                ),
              if (set.learnedCount > 0)
                TextButton.icon(
                  onPressed: isMarking ? null : onUnmarkAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Bỏ đánh dấu cả bộ'),
                ),
              if (isMarking)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          AppGap.sm,
          Text(
            'Mẹo: chạm vòng tròn bên phải mỗi từ để đánh dấu hoặc bỏ đánh dấu '
            'riêng từ đó.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
