import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import '../video/lesson_video_section.dart';

/// Một cảnh video của bài: xem tình huống thật diễn ra trước khi đọc lời thoại.
///
/// Mỗi cảnh là một bước riêng, nên video dừng ngay khi người học đi tiếp và
/// một bài nhiều cảnh vẫn được chia thành từng phần ngắn.
class StudyVideoStep extends StatelessWidget {
  const StudyVideoStep({super.key, required this.video});

  final LessonVideo video;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.transcript.isEmpty
              ? 'Xem cảnh này trước để thấy tình huống diễn ra thế nào.'
              : 'Xem cảnh này trước. Chạm vào một câu thoại để nghe lại đúng đoạn đó.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        AppGap.lg,
        LessonVideoSection(key: ValueKey(video.url), videos: [video]),
      ],
    );
  }
}
