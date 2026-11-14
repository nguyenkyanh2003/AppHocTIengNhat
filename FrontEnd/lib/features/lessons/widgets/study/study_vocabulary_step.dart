import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/pronounce.dart';
import '../../../vocabulary/models/vocabulary.dart';
import 'study_card_deck.dart';

/// Học từ vựng bằng thẻ lật, mỗi lần một từ (xem [StudyCardDeck]).
///
/// Mặt trước chỉ có chữ để người học tự nhớ cách đọc và nghĩa; chạm để lật.
class StudyVocabularyStep extends StatelessWidget {
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

  Future<void> _speak(BuildContext context, Vocabulary word) => pronounce(
        context,
        audioUrl: word.audioUrl,
        text: word.hiragana.isNotEmpty ? word.hiragana : word.word,
        hint: 'Thẻ vẫn học được bằng mắt.',
      );

  @override
  Widget build(BuildContext context) {
    return StudyCardDeck<Vocabulary>(
      items: words,
      unit: 'Từ',
      labelOf: (word) => word.word,
      isLearned: isLearned,
      isSaving: isSaving,
      onMarkLearned: onMarkLearned,
      onUnmarkLearned: onUnmarkLearned,
      front: (word) => _Front(word: word),
      back: (word) => _Back(word: word),
      onSpeak: (word) => _speak(context, word),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.word});

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
  const _Back({required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final example = word.examples.isEmpty ? null : word.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word.word, style: AppTypography.japaneseDisplay(size: AppTypography.display)),
        Text(word.hiragana, style: AppTypography.japaneseReading(color: context.colors.primary)),
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
