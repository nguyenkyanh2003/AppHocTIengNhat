import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/flashcard_deck.dart';

/// Hai mặt của một thẻ đang học, dù thẻ đến từ bộ thẻ tự tạo hay từ vựng.
typedef FlashcardFace = ({String front, String? frontSubtext, String back, String? backSubtext});

FlashcardFace faceOfCard(FlashcardCard card) =>
    (front: card.front, frontSubtext: card.frontSubtext, back: card.back, backSubtext: card.backSubtext);

/// Mặt sau của thẻ từ vựng có câu ví dụ đầu tiên nếu từ có.
FlashcardFace faceOfVocabulary(Vocabulary word) => (
      front: word.word,
      frontSubtext: word.hiragana,
      back: word.meaning,
      backSubtext: word.examples.isNotEmpty ? word.examples.first.sentence : null,
    );

/// Thanh tiến độ trên đầu màn học thẻ.
class FlashcardStudyProgress extends StatelessWidget {
  const FlashcardStudyProgress({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : current / total,
          minHeight: 10,
          backgroundColor: context.colors.border,
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
        ),
      ),
    );
  }
}

/// Không có thẻ nào để học.
class FlashcardStudyEmpty extends StatelessWidget {
  const FlashcardStudyEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: context.colors.textDisabled),
          const SizedBox(height: AppSpacing.lg),
          Text('Không có từ vựng để học', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
        ],
      ),
    );
  }
}
