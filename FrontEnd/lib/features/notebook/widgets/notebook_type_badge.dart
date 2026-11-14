import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/notebook.dart';

/// Mỗi loại ghi chú mang màu của mục học tương ứng.
extension NoteTypeColor on NoteType {
  Color get color => switch (this) {
        NoteType.vocabulary => AppTheme.vocabularyColor,
        NoteType.grammar => AppTheme.grammarColor,
        NoteType.kanji => AppTheme.kanjiColor,
        NoteType.lesson => AppTheme.lessonColor,
        NoteType.general => AppTheme.notebookColor,
      };
}

/// Nhãn loại ghi chú trên nền nhạt cùng màu.
class NotebookTypeBadge extends StatelessWidget {
  const NotebookTypeBadge({super.key, required this.type});

  final NoteType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: type.color.withValues(alpha: 0.1), borderRadius: AppRadius.pillAll),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: context.colors.readable(type.color),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
