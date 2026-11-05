import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Tên, mô tả và số liệu của bộ thẻ.
class FlashcardDeckHeader extends StatelessWidget {
  const FlashcardDeckHeader({
    super.key,
    required this.deck,
  });

  final FlashcardDeck deck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deck.title,
            style: const TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (deck.description != null && deck.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              deck.description!,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: context.colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(context, Icons.style, '${deck.totalCards} thẻ',
                  AppColors.primary),
              _buildStatChip(context, Icons.play_circle_outline,
                  '${deck.studyCount} lượt', AppColors.warning),
              if (deck.level != null)
                _buildStatChip(
                    context, Icons.bar_chart, deck.level!, Colors.purple),
            ],
          ),
          if (deck.totalCards > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startStudy(context, deck),
                icon: const Icon(Icons.school),
                label: const Text('Bắt đầu học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.readable(color)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.readable(color),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startStudy(BuildContext context, FlashcardDeck deck) {
    // Ghi nhận lượt học
    context.read<FlashcardProvider>().recordStudy(deck.id);

    // `extra` mang theo bộ thẻ; mở thẳng URL này thì route tự đưa về
    // trang bộ thẻ vì không có gì để khôi phục.
    context.push('/flashcards/${deck.id}/study', extra: deck);
  }
}
