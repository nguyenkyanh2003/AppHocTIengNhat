import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import '../video/lesson_video_section.dart';

/// Một video của bài: một cảnh tình huống, hoặc video ôn tập cuối chủ đề.
///
/// Mỗi video là một bước riêng, nên video dừng ngay khi người học đi tiếp và
/// một bài nhiều cảnh vẫn được chia thành từng phần ngắn.
class StudyVideoStep extends StatelessWidget {
  const StudyVideoStep({super.key, required this.video});

  final LessonVideo video;

  String get _hint {
    final lead = video.isReview
        ? 'Xem lại các mẫu câu của cả chủ đề trước khi sang phần hội thoại.'
        : 'Xem cảnh này trước để thấy tình huống diễn ra thế nào.';
    return video.transcript.isEmpty ? lead : '$lead Chạm vào một câu thoại để nghe lại đúng đoạn đó.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_hint, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        AppGap.lg,
        LessonVideoSection(key: ValueKey(video.url), videos: [video]),
      ],
    );
  }
}
