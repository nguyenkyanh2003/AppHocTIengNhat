import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../kanji/widgets/kanji_card_faces.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/srs_card.dart';

/// Hai mặt của một thẻ ôn. Thẻ từ vựng: mặt trước chỉ có từ, mặt sau có cách
/// đọc, nghĩa, Hán-Việt và một câu ví dụ. Thẻ Kanji: xem [KanjiCardFront].
///
/// Người học tự nhớ đáp án **trước** khi lật — lật là một thao tác riêng, nên
/// thẻ không bao giờ mở sẵn mặt sau.
class SrsFlashcard extends StatelessWidget {
  const SrsFlashcard({super.key, required this.card, required this.revealed, this.onReveal});

  final SrsCard card;
  final bool revealed;
  final VoidCallback? onReveal;

  static const double _minHeight = 280;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: InkWell(
        onTap: revealed || card.unavailable ? null : onReveal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              child: switch (card.item) {
                _ when card.unavailable => const _Unavailable(key: ValueKey('unavailable')),
                null => const _Unavailable(key: ValueKey('unavailable')),
                SrsVocabularyItem(:final vocabulary) => revealed
                    ? _VocabularyBack(key: const ValueKey('back'), item: vocabulary)
                    : _VocabularyFront(key: const ValueKey('front'), item: vocabulary),
                SrsKanjiItem(:final kanji) => revealed
                    ? KanjiCardBack(key: const ValueKey('back'), kanji: kanji)
                    : KanjiCardFront(key: const ValueKey('front'), kanji: kanji),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VocabularyFront extends StatelessWidget {
  const _VocabularyFront({super.key, required this.item});

  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.level != null) LevelBadge(item.level!),
        AppGap.lg,
        Text(item.word, style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
        AppGap.xl,
        Text(
          'Nhớ cách đọc và nghĩa rồi chạm để lật thẻ',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VocabularyBack extends StatelessWidget {
  const _VocabularyBack({super.key, required this.item});

  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final example = item.examples.isEmpty ? null : item.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.word, style: textTheme.headlineMedium, textAlign: TextAlign.center),
        AppGap.xs,
        Text(item.hiragana, style: textTheme.titleMedium?.copyWith(color: context.colors.primary)),
        if (item.hanviet?.isNotEmpty ?? false) ...[
          AppGap.xs,
          Text(item.hanviet!.toUpperCase(), style: textTheme.labelLarge),
        ],
        AppGap.lg,
        Text(item.meaning, style: textTheme.titleLarge, textAlign: TextAlign.center),
        if (example != null) ...[
          AppGap.lg,
          const Divider(),
          AppGap.sm,
          Text(example.sentence, style: textTheme.bodyLarge, textAlign: TextAlign.center),
          Text(example.meaning, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link_off, size: 48, color: context.colors.textDisabled),
        AppGap.md,
        Text('Nội dung không còn tồn tại', style: textTheme.titleMedium),
        AppGap.xs,
        Text(
          'Nội dung này đã bị xoá khỏi kho. Bỏ qua thẻ hoặc xoá nó khỏi lịch ôn.',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
