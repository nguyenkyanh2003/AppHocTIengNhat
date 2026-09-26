import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import 'lesson_transcript_view.dart';

/// Phần "Mẫu câu": các câu then chốt của video, mỗi câu một thẻ có nút nghe
/// lại đúng đoạn video của câu đó.
///
/// Không giữ trình phát — chỉ báo [onPlay]; thẻ đang phát được tô sáng theo
/// [playing] (vị trí câu trong lời thoại của video).
class LessonKeyPhraseList extends StatelessWidget {
  const LessonKeyPhraseList({
    super.key,
    required this.phrases,
    required this.layers,
    required this.playing,
    required this.onPlay,
  });

  final List<TranscriptLine> phrases;
  final Set<TranscriptLayer> layers;

  /// Câu đang được phát lại, `null` khi không phát câu nào.
  final TranscriptLine? playing;
  final ValueChanged<TranscriptLine> onPlay;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: phrases.length,
      separatorBuilder: (_, __) => AppGap.sm,
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        final active = identical(phrase, playing);
        return Material(
          color: active ? AppColors.primaryLight : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(color: active ? AppColors.primary : AppColors.border),
          ),
          child: InkWell(
            onTap: () => onPlay(phrase),
            borderRadius: AppRadius.mdAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    active ? Icons.graphic_eq_rounded : Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    semanticLabel: 'Nghe lại câu này',
                  ),
                  AppGap.sm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final row in transcriptLayerRows(phrase, layers))
                          TranscriptLayerRow(layer: row.layer, speaker: row.speaker, text: row.text),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
