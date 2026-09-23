import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky_card.dart';
import '../../../vocabulary/models/vocabulary.dart';

/// Từ vựng của bài, xem nhanh: chữ, cách đọc, nghĩa, và dấu đã nhớ. Chạm một
/// từ để mở trang chi tiết của từ đó.
class LessonWordGrid extends StatelessWidget {
  const LessonWordGrid({
    super.key,
    required this.words,
    required this.learnedIds,
    required this.onOpen,
  });

  final List<Vocabulary> words;
  final Set<String> learnedIds;
  final ValueChanged<Vocabulary> onOpen;

  static const double _tileWidth = 200;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _tileWidth).floor().clamp(1, 4);
        final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final word in words)
              SizedBox(
                width: width,
                child: ChunkyCard(
                  onTap: () => onOpen(word),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(word.word, style: AppTypography.japaneseBody()),
                            Text(word.hiragana, style: textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                            Text(word.meaning, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (learnedIds.contains(word.id))
                        const Icon(Icons.check_circle, size: 20, color: AppColors.success),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
