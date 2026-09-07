import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/vocabulary.dart';

/// Khối thông tin chính của một từ: chữ, cách đọc, nghĩa, cấp độ.
class VocabularyHeadline extends StatelessWidget {
  const VocabularyHeadline({
    super.key,
    required this.vocabulary,
    this.onPlayAudio,
  });

  final Vocabulary vocabulary;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              vocabulary.word,
              textAlign: TextAlign.center,
              style: AppTypography.japaneseDisplay.copyWith(
                color: AppColors.vocabulary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(vocabulary.hiragana, style: AppTypography.japaneseReading),
              if (vocabulary.audioUrl != null && onPlayAudio != null)
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  color: AppColors.vocabulary,
                  tooltip: 'Phát âm',
                  onPressed: onPlayAudio,
                ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text('Nghĩa', style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(vocabulary.meaning, style: textTheme.titleMedium),
          if (vocabulary.level != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text('Cấp độ', style: textTheme.labelMedium),
                const SizedBox(width: AppSpacing.sm),
                LevelBadge(vocabulary.level!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Ngữ cảnh sử dụng của từ.
class VocabularyUsageContext extends StatelessWidget {
  const VocabularyUsageContext({super.key, required this.usageContext});

  final String usageContext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngữ cảnh sử dụng', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(usageContext, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
