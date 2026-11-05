import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/kanji.dart';

/// Các từ ví dụ có chứa chữ, đánh số theo thứ tự.
class KanjiExampleList extends StatelessWidget {
  const KanjiExampleList({super.key, required this.examples});

  final List<KanjiExample> examples;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.kanjiCoral, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ví dụ',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (index, example) in examples.indexed)
            _ExampleTile(
              number: index + 1,
              example: example,
              isLast: index == examples.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.number, required this.example, required this.isLast});

  final int number;
  final KanjiExample example;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.kanjiCoral.withValues(alpha: 0.05),
            AppColors.kanjiCoralEnd.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.kanjiCoral.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.kanjiCoral, AppColors.kanjiCoralEnd],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: AppTypography.bodySmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  example.word,
                  style: TextStyle(
                    fontSize: AppTypography.subtitle,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example.hiragana,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            example.meaning,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
