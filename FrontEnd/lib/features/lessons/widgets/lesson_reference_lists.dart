import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/chunky_card.dart';

/// Chữ Hán của bài: mỗi ô một chữ, âm Hán-Việt và nghĩa — chỗ người Việt có
/// lợi thế nhất, nên Hán-Việt đứng ngay dưới chữ.
class LessonKanjiGrid extends StatelessWidget {
  const LessonKanjiGrid({super.key, required this.kanjis});

  final List<Map<String, dynamic>> kanjis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final kanji in kanjis)
          SizedBox(
            width: 140,
            child: ChunkyCard(
              child: Column(
                children: [
                  Text(kanji['character']?.toString() ?? '', style: AppTypography.japaneseDisplay()),
                  if (kanji['hanviet'] != null)
                    Text(kanji['hanviet'].toString().toUpperCase(), style: textTheme.labelLarge?.copyWith(color: AppColors.kanji)),
                  Text(
                    kanji['meaning']?.toString() ?? '',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Mẫu ngữ pháp của bài: cấu trúc, nghĩa và một câu ví dụ.
class LessonGrammarList extends StatelessWidget {
  const LessonGrammarList({super.key, required this.grammars});

  final List<Map<String, dynamic>> grammars;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final grammar in grammars)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ChunkyCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grammar['title']?.toString() ?? grammar['pattern']?.toString() ?? '',
                      style: AppTypography.japaneseBody()),
                  if (grammar['structure'] != null)
                    Text(grammar['structure'].toString(), style: textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
                  AppGap.xs,
                  Text(grammar['meaning']?.toString() ?? '', style: textTheme.bodyLarge),
                  for (final example in (grammar['examples'] as List? ?? const []).take(1).whereType<Map>()) ...[
                    AppGap.sm,
                    Text(example['sentence']?.toString() ?? '', style: AppTypography.japaneseReading(color: AppColors.textPrimary)),
                    Text(example['meaning']?.toString() ?? '', style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
