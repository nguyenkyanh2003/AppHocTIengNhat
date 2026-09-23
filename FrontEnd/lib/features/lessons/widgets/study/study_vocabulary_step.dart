import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/speech_service.dart';
import '../../../../shared/widgets/chunky_card.dart';
import '../../../vocabulary/models/vocabulary.dart';

/// Học từ vựng bằng thẻ lật, mỗi lần một từ.
///
/// Mặt trước chỉ có chữ để người học tự nhớ cách đọc và nghĩa; chạm để lật.
/// "Đã nhớ" lưu tiến độ ngay (và chuyển sang từ kế), nên rời bài giữa chừng
/// vẫn giữ những từ đã học.
class StudyVocabularyStep extends StatefulWidget {
  const StudyVocabularyStep({
    super.key,
    required this.words,
    required this.isLearned,
    required this.isSaving,
    required this.onMarkLearned,
  });

  final List<Vocabulary> words;
  final bool Function(Vocabulary word) isLearned;
  final bool Function(Vocabulary word) isSaving;
  final Future<void> Function(Vocabulary word) onMarkLearned;

  @override
  State<StudyVocabularyStep> createState() => _StudyVocabularyStepState();
}

class _StudyVocabularyStepState extends State<StudyVocabularyStep> {
  int _index = 0;
  bool _flipped = false;

  Vocabulary get _word => widget.words[_index];

  void _goTo(int index) => setState(() {
        _index = index.clamp(0, widget.words.length - 1);
        _flipped = false;
      });

  Future<void> _speak() async {
    try {
      if (_word.audioUrl != null) {
        await AudioService().playAudio(_word.audioUrl!);
      } else {
        await SpeechService.instance.speak(_word.hiragana.isNotEmpty ? _word.hiragana : _word.word);
      }
    } catch (_) {
      // Không có giọng đọc: thẻ vẫn học được bằng mắt.
    }
  }

  Future<void> _remember() async {
    final word = _word;
    await widget.onMarkLearned(word);
    if (mounted && widget.isLearned(word) && _index < widget.words.length - 1) _goTo(_index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final word = _word;
    final learned = widget.isLearned(word);
    final learnedCount = widget.words.where(widget.isLearned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Từ ${_index + 1}/${widget.words.length}', style: textTheme.titleSmall),
            const Spacer(),
            Text('Đã nhớ $learnedCount/${widget.words.length}',
                style: textTheme.labelLarge?.copyWith(color: AppColors.success)),
          ],
        ),
        AppGap.sm,
        ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: LinearProgressIndicator(
            value: learnedCount / widget.words.length,
            minHeight: AppSpacing.sm,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.success,
          ),
        ),
        AppGap.lg,
        ChunkyCard(
          onTap: () => setState(() => _flipped = !_flipped),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Stack(
            children: [
              // Chừa chỗ trên cùng cho nút nghe và nhãn "Đã nhớ", để chữ lớn
              // không bao giờ nằm dưới chúng.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: _flipped
                        ? _Back(key: const ValueKey('back'), word: word)
                        : _Front(key: const ValueKey('front'), word: word),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton.filledTonal(onPressed: _speak, tooltip: 'Nghe phát âm', icon: const Icon(Icons.volume_up)),
              ),
              if (learned)
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Chip(
                    avatar: Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    label: Text('Đã nhớ'),
                  ),
                ),
            ],
          ),
        ),
        AppGap.lg,
        Row(
          children: [
            IconButton.outlined(
              onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
              tooltip: 'Từ trước',
              icon: const Icon(Icons.chevron_left),
            ),
            AppGap.md,
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: learned || widget.isSaving(word) ? null : _remember,
                icon: const Icon(Icons.check),
                label: Text(learned ? 'Đã nhớ từ này' : 'Đã nhớ'),
              ),
            ),
            AppGap.md,
            IconButton.outlined(
              onPressed: _index < widget.words.length - 1 ? () => _goTo(_index + 1) : null,
              tooltip: 'Từ sau',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({super.key, required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word.word, style: AppTypography.japaneseDisplay(size: AppTypography.wordHero), textAlign: TextAlign.center),
        AppGap.lg,
        Text('Chạm để xem cách đọc và nghĩa', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({super.key, required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final example = word.examples.isEmpty ? null : word.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word.word, style: AppTypography.japaneseDisplay(size: AppTypography.display)),
        Text(word.hiragana, style: AppTypography.japaneseReading(color: AppColors.primary)),
        if (word.hanviet?.isNotEmpty ?? false) Text(word.hanviet!.toUpperCase(), style: textTheme.labelLarge),
        AppGap.md,
        Text(word.meaning, style: textTheme.headlineSmall, textAlign: TextAlign.center),
        if (example != null) ...[
          AppGap.md,
          Text(example.sentence, style: AppTypography.japaneseBody(), textAlign: TextAlign.center),
          Text(example.meaning, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
