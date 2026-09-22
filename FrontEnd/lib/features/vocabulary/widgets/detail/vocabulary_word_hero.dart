import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/level_badge.dart';
import '../../models/vocabulary.dart';
import 'detail_section.dart';

/// Thẻ từ chính: cấp độ, mặt chữ lớn, cách đọc, âm Hán-Việt, nút phát âm,
/// nghĩa và nút "Đã học".
class VocabularyWordHero extends StatelessWidget {
  const VocabularyWordHero({
    super.key,
    required this.vocabulary,
    required this.onSpeak,
    required this.onToggleLearned,
    this.togglingLearned = false,
  });

  final Vocabulary vocabulary;
  final VoidCallback onSpeak;
  final VoidCallback onToggleLearned;
  final bool togglingLearned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reading = vocabulary.hiragana;
    final hanviet = vocabulary.hanviet;

    return DetailSection(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              if (vocabulary.level != null) LevelBadge(vocabulary.level!),
              const Spacer(),
              if (vocabulary.usageContext != null)
                Flexible(
                  child: Text(
                    vocabulary.usageContext!,
                    style: textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          AppGap.xl,
          Text(
            vocabulary.word,
            textAlign: TextAlign.center,
            style: AppTypography.japaneseDisplay(
              size: AppTypography.wordHero,
              color: AppColors.textPrimary,
            ),
          ),
          if (reading.isNotEmpty && reading != vocabulary.word)
            Text(
              reading,
              textAlign: TextAlign.center,
              style: AppTypography.japaneseReading().copyWith(
                fontSize: AppTypography.subtitle,
              ),
            ),
          if (hanviet != null && hanviet.isNotEmpty) ...[
            AppGap.xs,
            Text(
              hanviet.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
          ],
          AppGap.lg,
          _SpeakButton(onPressed: onSpeak),
          AppGap.xl,
          const Divider(height: 1),
          AppGap.xl,
          Text(
            vocabulary.meaning,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          AppGap.xl,
          _LearnedButton(
            learned: vocabulary.isLearned,
            busy: togglingLearned,
            onPressed: onToggleLearned,
          ),
        ],
      ),
    );
  }
}

/// Nút loa tròn lớn — việc đầu tiên người học cần là nghe từ này đọc thế nào.
class _SpeakButton extends StatelessWidget {
  const _SpeakButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Nghe phát âm',
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
        ),
        child: const Icon(Icons.volume_up_rounded, size: AppSpacing.xxl),
      ),
    );
  }
}

/// "Đã học" xanh đặc, "Chưa học" viền xám — nhìn là biết trạng thái, bấm là
/// đổi.
class _LearnedButton extends StatelessWidget {
  const _LearnedButton({
    required this.learned,
    required this.busy,
    required this.onPressed,
  });

  final bool learned;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onTap = busy ? null : onPressed;
    const padding = EdgeInsets.symmetric(vertical: AppSpacing.md);

    final button = learned
        ? FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: padding,
            ),
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Đã học · đang trong lịch ôn tập'),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              padding: padding,
            ),
            icon: const Icon(Icons.radio_button_unchecked_rounded),
            label: const Text('Chưa học · bấm để đánh dấu'),
          );

    return SizedBox(width: double.infinity, child: button);
  }
}
