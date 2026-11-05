import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/kanji.dart';

/// Thẻ đầu tiên của trang chi tiết: Hán Việt và nghĩa, kèm [footer] (nút
/// thêm vào ôn tập) ở cuối.
class KanjiMeaningCard extends StatelessWidget {
  const KanjiMeaningCard({super.key, required this.kanji, this.footer});

  final Kanji kanji;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
          if (kanji.hanviet != null) ...[
            const _Label(icon: Icons.public, text: 'Hán Việt'),
            const SizedBox(height: 8),
            Text(
              kanji.hanviet!,
              style: TextStyle(
                fontSize: AppTypography.headline,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (kanji.meaning != null) ...[
            const _Label(icon: Icons.info_outline, text: 'Nghĩa'),
            const SizedBox(height: 8),
            Text(
              kanji.meaning!,
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                color: context.colors.textPrimary,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.kanjiCoral, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
