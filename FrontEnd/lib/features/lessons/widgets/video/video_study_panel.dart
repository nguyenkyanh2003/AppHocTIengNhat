import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import 'lesson_key_phrase_list.dart';
import 'lesson_transcript_view.dart';
import 'lesson_video_word_table.dart';

/// Khung học đặt cạnh video: "Kịch bản" (lời thoại chạy theo video), "Mẫu câu"
/// (câu then chốt, nghe lại từng câu) và "Từ vựng" (bảng từ của video).
///
/// Chỉ hiện phần video thật sự có; có một phần thì bỏ luôn thanh tab. Ba nút
/// 日本語 / Roma-ji / Tiếng Việt đứng trên cùng, dùng chung cho Kịch bản và Mẫu
/// câu. Widget này không giữ trình phát — mọi thao tác phát báo ngược lên cha.
///
/// Cần nằm trong khung có chiều cao xác định: mỗi phần tự cuộn bên trong.
class VideoStudyPanel extends StatelessWidget {
  const VideoStudyPanel({
    super.key,
    required this.video,
    required this.activeLine,
    required this.playingPhrase,
    required this.layers,
    required this.onSeek,
    required this.onPlayPhrase,
  });

  final LessonVideo video;

  /// Vị trí câu đang nói trong lời thoại, `null` ở khoảng lặng.
  final ValueListenable<int?> activeLine;

  /// Câu then chốt đang được phát lại.
  final ValueListenable<TranscriptLine?> playingPhrase;

  final ValueNotifier<Set<TranscriptLayer>> layers;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<TranscriptLine> onPlayPhrase;

  @override
  Widget build(BuildContext context) {
    final phrases = video.keyPhrases;
    final sections = [
      if (video.transcript.isNotEmpty)
        (
          label: 'Kịch bản',
          child: ValueListenableBuilder<int?>(
            valueListenable: activeLine,
            builder: (context, active, _) => LessonTranscriptView(
              lines: video.transcript,
              activeIndex: active,
              layers: layers,
              showLayerToggles: false,
              onSeek: onSeek,
            ),
          ),
        ),
      if (phrases.isNotEmpty)
        (
          label: 'Mẫu câu',
          child: ValueListenableBuilder<Set<TranscriptLayer>>(
            valueListenable: layers,
            builder: (context, selected, _) => ValueListenableBuilder<TranscriptLine?>(
              valueListenable: playingPhrase,
              builder: (context, playing, _) => LessonKeyPhraseList(
                phrases: phrases,
                layers: selected,
                playing: playing,
                onPlay: onPlayPhrase,
              ),
            ),
          ),
        ),
      if (video.vocabulary.isNotEmpty) (label: 'Từ vựng', child: LessonVideoWordTable(words: video.vocabulary)),
    ];
    if (sections.isEmpty) return const SizedBox.shrink();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (video.transcript.isNotEmpty) ...[
          TranscriptLayerToggles(layers: layers),
          AppGap.md,
        ],
        if (sections.length > 1) ...[
          TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            tabs: [for (final section in sections) Tab(text: section.label)],
          ),
          AppGap.sm,
          Expanded(child: TabBarView(children: [for (final section in sections) section.child])),
        ] else
          Expanded(child: sections.single.child),
      ],
    );

    return DefaultTabController(length: sections.length, child: body);
  }
}
