import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/grammar.dart';
import 'grammar_detail_section.dart';

/// Nội dung một bài ngữ pháp: đầu trang theo màu cấp độ, nghĩa, cách dùng, ví dụ
/// và lượt xem.
class GrammarDetailBody extends StatelessWidget {
  const GrammarDetailBody({super.key, required this.grammar});

  final Grammar grammar;

  @override
  Widget build(BuildContext context) {
    final levelColor = AppTheme.getJlptLevelColor(grammar.level);
    final explanation = grammar.explanation;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            color: levelColor.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LevelBadge(grammar.level),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  grammar.title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: AppTypography.headline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pattern: ${grammar.pattern}',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: AppTypography.bodySmall),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GrammarDetailSection(title: 'Ý Nghĩa', content: grammar.meaning, icon: Icons.description),
                const SizedBox(height: AppSpacing.xl),
                if (explanation != null && explanation.isNotEmpty) ...[
                  GrammarDetailSection(title: 'Giải Thích', content: explanation, icon: Icons.info),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (grammar.examples.isNotEmpty) ...[
                  const GrammarSectionTitle(title: 'Ví Dụ', icon: Icons.lightbulb),
                  const SizedBox(height: AppSpacing.md),
                  for (final (index, example) in grammar.examples.indexed)
                    _ExampleCard(number: index + 1, text: example, accent: levelColor),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(label: 'Lượt Xem', value: '${grammar.viewCount}', icon: Icons.visibility),
                    _StatCard(label: 'Cấp Độ', value: grammar.level, icon: Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.number, required this.text, required this.accent});

  final int number;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: AppRadius.smAll,
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ví dụ $number:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTypography.caption,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(fontSize: AppTypography.bodySmall, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: context.colors.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary, size: 24),
              const SizedBox(height: AppSpacing.sm),
              Text(value, style: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
