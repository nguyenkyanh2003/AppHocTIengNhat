import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/lesson.dart';

/// Bài có những gì: số cảnh video, câu thoại, từ, chữ Hán, mẫu ngữ pháp.
///
/// Chỉ hiện loại nội dung bài thật sự có — một ô "0/0 Kanji" không cho người
/// học biết thêm gì mà chỉ làm bài trông thiếu.
class LessonContentChips extends StatelessWidget {
  const LessonContentChips({super.key, required this.detail});

  final LessonDetail detail;

  @override
  Widget build(BuildContext context) {
    final lesson = detail.lesson;
    final items = [
      if (lesson.videos.isNotEmpty) (Icons.play_circle_outline, '${lesson.videos.length} cảnh video'),
      if (lesson.dialogue.isNotEmpty) (Icons.forum_outlined, '${lesson.dialogue.length} câu thoại'),
      if (detail.words.isNotEmpty) (Icons.style_outlined, '${detail.words.length} từ vựng'),
      if (detail.kanjis.isNotEmpty) (Icons.draw_outlined, '${detail.kanjis.length} chữ Hán'),
      if (detail.grammars.isNotEmpty) (Icons.account_tree_outlined, '${detail.grammars.length} mẫu ngữ pháp'),
    ];
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (icon, label) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.pillAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                AppGap.xs,
                Text(label, style: textTheme.labelLarge?.copyWith(color: AppColors.primaryDark)),
              ],
            ),
          ),
      ],
    );
  }
}
