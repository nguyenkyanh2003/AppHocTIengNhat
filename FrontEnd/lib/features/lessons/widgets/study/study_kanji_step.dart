import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../kanji/models/kanji.dart';
import '../../../kanji/widgets/kanji_card_faces.dart';
import 'study_card_deck.dart';

/// Học chữ Hán của bài bằng thẻ lật (xem [StudyCardDeck]), cùng hai mặt thẻ
/// với phiên ôn tập: mặt trước chỉ có chữ, mặt sau có Hán Việt, âm đọc, nghĩa
/// và một từ ví dụ. [footer] nằm dưới bộ thẻ — màn học đặt lời mời thêm vào
/// ôn tập ở đó.
class StudyKanjiStep extends StatelessWidget {
  const StudyKanjiStep({
    super.key,
    required this.kanjis,
    required this.isLearned,
    required this.isSaving,
    required this.onMarkLearned,
    required this.onUnmarkLearned,
    this.footer,
  });

  final List<Kanji> kanjis;
  final bool Function(Kanji kanji) isLearned;
  final bool Function(Kanji kanji) isSaving;
  final Future<void> Function(Kanji kanji) onMarkLearned;
  final Future<void> Function(Kanji kanji) onUnmarkLearned;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudyCardDeck<Kanji>(
          items: kanjis,
          unit: 'Chữ',
          labelOf: (kanji) => kanji.character,
          isLearned: isLearned,
          isSaving: isSaving,
          onMarkLearned: onMarkLearned,
          onUnmarkLearned: onUnmarkLearned,
          front: (kanji) => KanjiCardFront(kanji: kanji),
          back: (kanji) => KanjiCardBack(kanji: kanji),
        ),
        if (footer != null) ...[AppGap.xl, footer!],
      ],
    );
  }
}

/// Lời mời đưa những chữ đã nhớ vào lịch ôn tập.
///
/// Không tự thêm khi bấm "Đã nhớ": thuộc trong bài và muốn ôn lại lâu dài là
/// hai quyết định khác nhau, và thẻ ôn nào cũng sẽ đòi thời gian mỗi ngày.
class StudyKanjiReviewOffer extends StatelessWidget {
  const StudyKanjiReviewOffer({
    super.key,
    required this.pending,
    required this.added,
    required this.busy,
    required this.onAdd,
  });

  /// Số chữ đã nhớ nhưng chưa thêm trong phiên này.
  final int pending;
  final int added;
  final bool busy;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (pending > 0) {
      return FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
        onPressed: busy ? null : onAdd,
        icon: busy
            ? const SizedBox.square(
                dimension: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.event_repeat),
        label: Text('Thêm $pending chữ đã nhớ vào ôn tập'),
      );
    }

    if (added > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle,
              color: context.colors.readable(AppColors.success)),
          AppGap.sm,
          Flexible(
              child: Text('Đã thêm $added chữ vào lịch ôn tập',
                  style: textTheme.bodyMedium)),
        ],
      );
    }

    return Text(
      'Bấm "Đã nhớ" ở chữ bạn đã thuộc để có thể đưa chữ đó vào lịch ôn tập.',
      style: textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}
