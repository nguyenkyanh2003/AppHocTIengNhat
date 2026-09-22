import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../models/vocabulary.dart';
import 'detail_section.dart';

/// Câu ví dụ của từ, mỗi câu có nút nghe và bản dịch.
///
/// Phần lớn từ chưa có câu ví dụ trong dữ liệu, nên trạng thái rỗng là trạng
/// thái thường gặp — hiện một dòng nhẹ thay vì giấu cả khối, để người học
/// biết mục này có và sẽ được bổ sung.
class VocabularyExampleList extends StatelessWidget {
  const VocabularyExampleList({
    super.key,
    required this.examples,
    required this.onSpeak,
  });

  final List<VocabExample> examples;
  final ValueChanged<VocabExample> onSpeak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DetailSection(
      title: 'Câu ví dụ',
      icon: Icons.format_quote_rounded,
      trailing: examples.isEmpty
          ? null
          : Text('${examples.length} câu', style: textTheme.labelMedium),
      child: examples.isEmpty
          ? Text(
              'Chưa có câu ví dụ cho từ này.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < examples.length; index++) ...[
                  if (index > 0) const Divider(height: AppSpacing.xl),
                  _ExampleRow(
                    example: examples[index],
                    onSpeak: () => onSpeak(examples[index]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.example, required this.onSpeak});

  final VocabExample example;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onSpeak,
          tooltip: 'Nghe câu này',
          color: AppColors.primary,
          icon: const Icon(Icons.volume_up_outlined),
        ),
        AppGap.sm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                example.sentence,
                style: AppTypography.japaneseReading(
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: AppTypography.subtitle),
              ),
              if (example.meaning.isNotEmpty) ...[
                AppGap.xs,
                Text(
                  example.meaning,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
