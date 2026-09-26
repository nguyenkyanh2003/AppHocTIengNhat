import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/lesson.dart';
import '../models/lesson_video.dart';
import '../providers/lesson_provider.dart';
import '../widgets/transcript_editor/transcript_timing_editor.dart';

/// Công cụ soạn lời thoại chạy theo video (chỉ quản trị viên).
///
/// Mốc thời gian của từng câu chỉ có được khi ngồi xem video; màn này biến
/// việc đó thành bấm Space theo video. Kết quả là đoạn văn bản đúng định dạng
/// `data/lesson-videos/<bài>.txt` ở backend — nguồn sự thật của lời thoại vẫn
/// là file đó, app không ghi thẳng vào database.
class LessonTranscriptEditorScreen extends StatefulWidget {
  const LessonTranscriptEditorScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonTranscriptEditorScreen> createState() => _LessonTranscriptEditorScreenState();
}

class _LessonTranscriptEditorScreenState extends State<LessonTranscriptEditorScreen> {
  int _videoIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessons = context.read<LessonProvider>();
      if (lessons.currentLessonDetail?.lesson.id != widget.lessonId) {
        lessons.loadLessonDetail(widget.lessonId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<LessonProvider>();
    return AppScaffold(
      title: 'Soạn lời thoại video',
      body: AsyncView<LessonDetail>(
        state: lessons.detailState,
        onRetry: () => lessons.loadLessonDetail(widget.lessonId),
        builder: (context, detail) {
          if (detail.lesson.id != widget.lessonId) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = detail.lesson.videos;
          if (videos.isEmpty) {
            return const Center(child: Text('Bài học này chưa có video.'));
          }
          final index = _videoIndex.clamp(0, videos.length - 1);
          return SingleChildScrollView(
            child: ContentPane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(detail.lesson.displayTitle, style: Theme.of(context).textTheme.titleLarge),
                  AppGap.md,
                  _VideoChoice(videos: videos, selected: index, onSelected: (value) => setState(() => _videoIndex = value)),
                  AppGap.lg,
                  TranscriptTimingEditor(key: ValueKey(videos[index].url), video: videos[index]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Chọn video cần soạn; video đã có lời thoại được đánh dấu để biết còn thiếu đâu.
class _VideoChoice extends StatelessWidget {
  const _VideoChoice({required this.videos, required this.selected, required this.onSelected});

  final List<LessonVideo> videos;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < videos.length; index++)
          ChoiceChip(
            avatar: videos[index].transcript.isEmpty ? null : const Icon(Icons.check_circle_outline),
            label: Text(switch (sceneNumber(videos, index)) {
              final number? => 'Cảnh $number: ${videos[index].title}',
              null => videos[index].title,
            }),
            selected: index == selected,
            onSelected: (_) => onSelected(index),
          ),
      ],
    );
  }
}
