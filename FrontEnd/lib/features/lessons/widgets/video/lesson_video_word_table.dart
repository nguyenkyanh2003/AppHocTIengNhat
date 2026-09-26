import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../models/lesson_video.dart';

/// Phần "Từ vựng": bảng bốn cột mặt chữ / cách đọc / roma-ji / nghĩa.
class LessonVideoWordTable extends StatelessWidget {
  const LessonVideoWordTable({super.key, required this.words});

  final List<VideoWord> words;

  static const _headers = ['Từ', 'Cách đọc', 'Roma-ji', 'Tiếng Việt'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final japanese = AppTypography.japaneseReading(color: AppColors.textPrimary).copyWith(fontSize: AppTypography.body);

    TableRow row(List<Widget> cells, {Color? color}) => TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            for (final cell in cells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                child: cell,
              ),
          ],
        );

    return SingleChildScrollView(
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Table(
          border: const TableBorder(horizontalInside: BorderSide(color: AppColors.border)),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(3),
            3: FlexColumnWidth(4),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            row(
              [for (final header in _headers) Text(header, style: textTheme.labelLarge)],
              color: AppColors.primaryLight,
            ),
            for (final word in words)
              row([
                Text(word.word, style: japanese),
                Text(word.reading ?? '', style: japanese),
                Text(word.romaji ?? '', style: textTheme.bodySmall),
                Text(word.meaning, style: textTheme.bodyMedium),
              ]),
          ],
        ),
      ),
    );
  }
}
