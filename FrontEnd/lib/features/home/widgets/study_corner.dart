import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';
import 'home_layout.dart';

/// "Góc học tập": bảy lối tắt tới các mảng học, lưới 4 cột trong một thẻ.
///
/// Thay cho lưới 7 thẻ lớn cũ (gần một màn hình, dòng mô tả bị cắt, thừa một ô
/// trống). Chỉ còn icon và tên; mỗi ô là một vùng bấm trọn vẹn.
class StudyCorner extends StatelessWidget {
  const StudyCorner({super.key});

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final items = [
      _Item(l10n.menuLesson, '/lessons', StudyCornerTone.lesson,
          icon: Icons.menu_book_outlined),
      _Item(l10n.menuVocabulary, '/vocabulary', StudyCornerTone.vocabulary,
          icon: Icons.translate_rounded),
      _Item(l10n.menuKanji, '/kanji', StudyCornerTone.kanji, glyph: '漢'),
      _Item(l10n.menuExercise, '/exercise', StudyCornerTone.exercise,
          icon: Icons.edit_note_rounded),
      _Item(l10n.menuJlpt, '/jlpt', StudyCornerTone.jlpt,
          icon: Icons.workspace_premium_outlined),
      _Item(l10n.menuStudyGroup, '/study-groups', StudyCornerTone.group,
          icon: Icons.groups_outlined),
      _Item(l10n.menuNotebook, '/notebook', StudyCornerTone.notebook,
          icon: Icons.sticky_note_2_outlined),
    ];

    final rows = <Widget>[];
    for (var start = 0; start < items.length; start += _columns) {
      final row = items.skip(start).take(_columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in row) Expanded(child: _Tile(item: item)),
          // Hàng cuối thiếu ô thì chừa chỗ trống, để cột vẫn thẳng hàng trên.
          for (var i = row.length; i < _columns; i++) const Spacer(),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: homeCardDecoration(calm, radius: 20),
      child: Column(children: rows),
    );
  }
}

class _Item {
  const _Item(this.label, this.route, this.tone, {this.icon, this.glyph});

  final String label;
  final String route;
  final StudyCornerTone tone;
  final IconData? icon;

  /// Chữ thay cho icon (ô Kanji dùng chữ 漢).
  final String? glyph;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final colors = calm.tiles[item.tone]!;

    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(item.route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minHeight: HomeLayout.minTap, minWidth: HomeLayout.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(18)),
                  child: item.glyph != null
                      ? Text(
                          item.glyph!,
                          style: AppTypography.japaneseDisplay(
                                  size: 25, color: colors.foreground)
                              .copyWith(height: 1),
                        )
                      : Icon(item.icon, size: 26, color: colors.foreground),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(
                      size: 13,
                      weight: FontWeight.w600,
                      color: calm.textPrimary,
                      height: 1.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
