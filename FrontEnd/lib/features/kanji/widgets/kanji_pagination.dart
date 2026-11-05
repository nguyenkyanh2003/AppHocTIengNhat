import 'package:flutter/material.dart';
import '../providers/kanji_provider.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Nút chuyển trang của danh sách Kanji.
class KanjiPagination extends StatelessWidget {
  const KanjiPagination({
    super.key,
    required this.provider,
  });

  final KanjiProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: provider.hasPreviousPage
                  ? () => provider.previousPage()
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Trước'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kanjiCoral,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Text(
              'Trang ${provider.currentPage}/${provider.totalPages}',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  provider.hasNextPage ? () => provider.nextPage() : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Sau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kanjiCoral,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
