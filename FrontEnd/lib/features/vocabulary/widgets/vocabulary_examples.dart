import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/vocabulary.dart';

/// Danh sách câu ví dụ của một từ.
class VocabularyExamples extends StatelessWidget {
  const VocabularyExamples({
    super.key,
    required this.examples,
    this.onPlayAudio,
  });

  final List<VocabExample> examples;
  final void Function(VocabExample example)? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.exercise),
              const SizedBox(width: AppSpacing.sm),
              Text('Ví dụ câu', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final example in examples) ...[
            _ExampleTile(
              example: example,
              onPlayAudio:
                  onPlayAudio == null ? null : () => onPlayAudio!(example),
            ),
            if (example != examples.last) const Divider(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.example, this.onPlayAudio});

  final VocabExample example;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(example.sentence, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(example.meaning, style: textTheme.bodySmall),
            ],
          ),
        ),
        if (example.audioUrl != null && onPlayAudio != null)
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            color: AppColors.exercise,
            tooltip: 'Phát âm ví dụ',
            onPressed: onPlayAudio,
          ),
      ],
    );
  }
}
