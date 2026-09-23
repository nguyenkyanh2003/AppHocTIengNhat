import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/srs_card.dart';

/// Hai mặt của một thẻ ôn: mặt trước chỉ có từ, mặt sau có cách đọc, nghĩa,
/// Hán-Việt và một câu ví dụ.
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
              child: card.unavailable
                  ? const _Unavailable(key: ValueKey('unavailable'))
                  : revealed
                      ? _Back(key: const ValueKey('back'), card: card)
                      : _Front(key: const ValueKey('front'), card: card),
            ),
          ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({super.key, required this.card});

  final SrsCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = card.item!;
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

class _Back extends StatelessWidget {
  const _Back({super.key, required this.card});

  final SrsCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final item = card.item!;
    final example = item.examples.isEmpty ? null : item.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.word, style: textTheme.headlineMedium, textAlign: TextAlign.center),
        AppGap.xs,
        Text(item.hiragana, style: textTheme.titleMedium?.copyWith(color: AppColors.primary)),
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
        const Icon(Icons.link_off, size: 48, color: AppColors.textDisabled),
        AppGap.md,
        Text('Nội dung không còn tồn tại', style: textTheme.titleMedium),
        AppGap.xs,
        Text(
          'Từ này đã bị xoá khỏi kho. Bỏ qua thẻ hoặc xoá nó khỏi lịch ôn.',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
