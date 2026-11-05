import 'package:flutter/material.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Tiêu đề một mục của bài ngữ pháp.
class GrammarSectionTitle extends StatelessWidget {
  const GrammarSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.colors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.subtitle,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Một mục nội dung của bài ngữ pháp.
class GrammarDetailSection extends StatelessWidget {
  const GrammarDetailSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrammarSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: AppTypography.bodySmall,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
