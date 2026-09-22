import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../models/vocabulary.dart';
import 'detail_section.dart';

/// Từ liên quan: có chung chữ Hán với từ đang xem, hoặc cùng chủ đề nếu từ
/// không có chữ Hán. Bấm một từ để mở chi tiết từ đó.
class VocabularyRelatedWords extends StatelessWidget {
  const VocabularyRelatedWords({
    super.key,
    required this.words,
    required this.onOpen,
  });

  final List<Vocabulary> words;
  final ValueChanged<Vocabulary> onOpen;

  static const double _tileMinWidth = 180;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DetailSection(
      title: 'Từ liên quan',
      icon: Icons.hub_outlined,
      child: words.isEmpty
          ? Text(
              'Chưa tìm thấy từ liên quan.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Hai cột khi đủ chỗ, một cột trên màn hẹp.
                final columns =
                    constraints.maxWidth >= _tileMinWidth * 2 + AppSpacing.md
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                        columns;

                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final word in words)
                      SizedBox(
                        width: width,
                        child: HoverLift(
                          onTap: () => onOpen(word),
                          child: _RelatedTile(word: word),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showReading = word.hiragana.isNotEmpty && word.hiragana != word.word;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.word,
                style: AppTypography.japaneseReading(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: AppTypography.subtitle,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (showReading)
                Text(
                  word.hiragana,
                  style: AppTypography.japaneseReading(),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                word.meaning,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (word.level != null) Text(word.level!, style: textTheme.labelSmall),
      ],
    );
  }
}
