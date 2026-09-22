import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../models/vocabulary.dart';
import 'detail_section.dart';

/// Tách từ thành từng chữ Hán: chữ, âm Hán-Việt và nghĩa riêng (nếu có).
///
/// Chữ đã có trong mục Kanji thì bấm được để mở trang chi tiết chữ.
class VocabularyKanjiBreakdown extends StatelessWidget {
  const VocabularyKanjiBreakdown({
    super.key,
    required this.parts,
    required this.onOpenKanji,
  });

  final List<KanjiPart> parts;
  final ValueChanged<String> onOpenKanji;

  static const double _tileWidth = 132;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DetailSection(
      title: 'Phân tích chữ Hán',
      icon: Icons.account_tree_outlined,
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final part in parts)
            SizedBox(
              width: _tileWidth,
              child: HoverLift(
                onTap: part.kanjiId == null
                    ? null
                    : () => onOpenKanji(part.kanjiId!),
                tooltip: part.kanjiId == null ? null : 'Xem chi tiết chữ',
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      part.character,
                      style: AppTypography.japaneseDisplay(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      part.hanviet?.toUpperCase() ?? '—',
                      style: textTheme.labelLarge?.copyWith(letterSpacing: 1),
                    ),
                    if (part.meaning != null) ...[
                      AppGap.xs,
                      Text(
                        part.meaning!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
