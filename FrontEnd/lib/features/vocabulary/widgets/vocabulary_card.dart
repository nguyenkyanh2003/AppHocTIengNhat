import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/vocabulary.dart';

/// Một dòng từ vựng trong danh sách.
class VocabularyCard extends StatelessWidget {
  const VocabularyCard({
    super.key,
    required this.vocabulary,
    this.onTap,
    this.onAddToFlashcard,
    this.onPlayAudio,
  });

  final Vocabulary vocabulary;
  final VoidCallback? onTap;
  final VoidCallback? onAddToFlashcard;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      accent: AppColors.vocabulary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vocabulary.word,
                        style: textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vocabulary.level != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      LevelBadge(vocabulary.level!, compact: true),
                    ],
                    if (vocabulary.isLearned) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                if (vocabulary.hiragana.isNotEmpty)
                  Text(vocabulary.hiragana, style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vocabulary.meaning,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (vocabulary.audioUrl != null && onPlayAudio != null)
            IconButton(
              icon: const Icon(Icons.volume_up_outlined),
              color: AppColors.vocabulary,
              tooltip: 'Phát âm',
              onPressed: onPlayAudio,
            ),
          if (onAddToFlashcard != null)
            IconButton(
              icon: const Icon(Icons.add_card),
              color: AppColors.vocabulary,
              tooltip: 'Thêm vào Flashcard',
              onPressed: onAddToFlashcard,
            ),
        ],
      ),
    );
  }
}
