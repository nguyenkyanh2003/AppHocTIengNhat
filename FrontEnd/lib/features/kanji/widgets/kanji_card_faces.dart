import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/kanji.dart';

/// Mặt trước thẻ Kanji: chỉ có chữ — người học tự nhớ âm đọc và nghĩa.
class KanjiCardFront extends StatelessWidget {
  const KanjiCardFront({super.key, required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kanji.level != null) LevelBadge(kanji.level!),
        AppGap.lg,
        Text(kanji.character, style: theme.textTheme.displayLarge, textAlign: TextAlign.center),
        AppGap.xl,
        Text(
          'Nhớ âm đọc và nghĩa rồi chạm để lật thẻ',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Mặt sau thẻ Kanji: Hán Việt, Âm Hán (onyomi), Âm Kun (kunyomi), nghĩa và
/// một từ ví dụ.
class KanjiCardBack extends StatelessWidget {
  const KanjiCardBack({super.key, required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final example = kanji.examples.isEmpty ? null : kanji.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kanji.character, style: textTheme.headlineLarge, textAlign: TextAlign.center),
        if (kanji.hanviet?.isNotEmpty ?? false) ...[
          AppGap.xs,
          Text(kanji.hanviet!.toUpperCase(), style: textTheme.labelLarge),
        ],
        AppGap.md,
        if (kanji.onyomi.isNotEmpty)
          _Reading(label: 'Âm Hán', value: kanji.onyomi.join('、'), color: AppColors.primary),
        if (kanji.kunyomi.isNotEmpty)
          _Reading(label: 'Âm Kun', value: kanji.kunyomi.join('、'), color: AppColors.success),
        if (kanji.meaning?.isNotEmpty ?? false) ...[
          AppGap.md,
          Text(kanji.meaning!, style: textTheme.titleLarge, textAlign: TextAlign.center),
        ],
        if (example != null) ...[
          AppGap.lg,
          const Divider(),
          AppGap.sm,
          Text('${example.word}（${example.hiragana}）', style: textTheme.bodyLarge, textAlign: TextAlign.center),
          Text(example.meaning, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
            child: Text(label, style: textTheme.labelMedium?.copyWith(color: context.colors.readable(color))),
          ),
          AppGap.sm,
          Flexible(child: Text(value, style: textTheme.titleMedium)),
        ],
      ),
    );
  }
}
