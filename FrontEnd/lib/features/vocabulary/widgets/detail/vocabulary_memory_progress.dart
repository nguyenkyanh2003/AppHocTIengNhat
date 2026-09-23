import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/vocabulary.dart';
import 'detail_section.dart';

/// Mức ghi nhớ của từ theo hộp SRS (Leitner 1–5): mỗi lần ôn đúng từ lên một
/// hộp và lần ôn sau cách xa hơn, ôn sai thì về hộp 1.
///
/// Có lịch ôn thì kèm ngày ôn tới và nút đặt lại lịch — đặt lại được cả khi
/// thẻ chưa đến hạn, điều màn ôn tập không làm được.
class VocabularyMemoryProgress extends StatelessWidget {
  const VocabularyMemoryProgress({
    super.key,
    required this.vocabulary,
    this.onResetSchedule,
    this.resetting = false,
  });

  final Vocabulary vocabulary;
  final VoidCallback? onResetSchedule;
  final bool resetting;

  static const int maxBox = 5;
  static const List<String> _labels = [
    'Mới nhớ',
    'Đang quen',
    'Khá nhớ',
    'Nhớ tốt',
    'Thuộc lòng',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final learned = vocabulary.isLearned;
    final box = learned ? (vocabulary.reviewBox ?? 1).clamp(1, maxBox) : 0;

    return DetailSection(
      title: 'Mức ghi nhớ',
      icon: Icons.psychology_alt_outlined,
      trailing: learned
          ? Text('Hộp $box/$maxBox', style: textTheme.labelLarge)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 0; index < maxBox; index++) ...[
                if (index > 0) AppGap.xs,
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      color: index < box
                          ? AppColors.success
                          : AppColors.surfaceVariant,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppGap.md,
          Text(
            learned
                ? _labels[box - 1]
                : 'Chưa học — đánh dấu "Đã học" để từ này vào lịch ôn tập.',
            style: learned ? textTheme.titleSmall : textTheme.bodySmall,
          ),
          if (vocabulary.srsProgress case final progress?) ...[
            AppGap.xs,
            Text('Lần ôn tới: ${_formatDate(progress.nextReview)}', style: textTheme.bodySmall),
            if (onResetSchedule != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: resetting ? null : onResetSchedule,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Đặt lại lịch ôn'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
