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
/// vẫn giữ những từ đã học. Bấm nhầm thì hoàn tác ngay trên thông báo, hoặc
/// quay lại từ đó và bấm "Bỏ đánh dấu".
class StudyVocabularyStep extends StatefulWidget {
  const StudyVocabularyStep({
    super.key,
    required this.words,
    required this.isLearned,
    required this.isSaving,
    required this.onMarkLearned,
    required this.onUnmarkLearned,
  });

  final List<Vocabulary> words;
  final bool Function(Vocabulary word) isLearned;
  final bool Function(Vocabulary word) isSaving;
  final Future<void> Function(Vocabulary word) onMarkLearned;
  final Future<void> Function(Vocabulary word) onUnmarkLearned;

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
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_word.audioUrl != null) {
        await AudioService().playAudio(_word.audioUrl!);
      } else {
        await SpeechService.instance.speak(_word.hiragana.isNotEmpty ? _word.hiragana : _word.word);
      }
    } on SpeechUnavailableException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error Thẻ vẫn học được bằng mắt.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Không phát được âm thanh.')));
    }
  }

  Future<void> _remember() async {
    final word = _word;
    final index = _index;
    final messenger = ScaffoldMessenger.of(context);
    await widget.onMarkLearned(word);
    if (!mounted || !widget.isLearned(word)) return;
    if (_index < widget.words.length - 1) _goTo(_index + 1);

    // Thẻ đã chuyển sang từ kế: hoàn tác ngay tại đây thì không phải lùi lại tìm.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Đã nhớ「${word.word}」'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            await widget.onUnmarkLearned(word);
            if (mounted) _goTo(index);
          },
        ),
      ));
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
        _WordProgress(
          current: _index,
          learned: [for (final word in widget.words) widget.isLearned(word)],
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
              child: learned
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: widget.isSaving(word) ? null : () => widget.onUnmarkLearned(word),
                      icon: const Icon(Icons.undo),
                      label: const Text('Bỏ đánh dấu đã nhớ'),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: widget.isSaving(word) ? null : _remember,
                      icon: const Icon(Icons.check),
                      label: const Text('Đã nhớ'),
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

/// Mỗi ô là một từ: ô tới từ đang xem thì tô màu (thanh chạy theo "Từ 7/9"),
/// ô của từ đã nhớ thì tô xanh — một thanh cho biết cả đang ở đâu lẫn đã nhớ
/// những từ nào.
class _WordProgress extends StatelessWidget {
  const _WordProgress({required this.current, required this.learned});

  final int current;
  final List<bool> learned;

  @override
  Widget build(BuildContext context) {
    final learnedCount = learned.where((value) => value).length;
    return Semantics(
      label: 'Từ ${current + 1} trên ${learned.length}, đã nhớ $learnedCount',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < learned.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs / 2),
              Expanded(
                child: AnimatedContainer(
                  key: ValueKey('word-progress-$index'),
                  duration: AppDurations.fast,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillAll,
                    color: learned[index]
                        ? AppColors.success
                        : index <= current
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
