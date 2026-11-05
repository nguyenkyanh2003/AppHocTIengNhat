import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import 'flashcard_deck_dialogs.dart';

/// Một thẻ trong bộ.
class FlashcardCardItem extends StatelessWidget {
  const FlashcardCardItem({
    super.key,
    required this.card,
    required this.index,
    required this.deckId,
  });

  final FlashcardCard card;
  final int index;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditCardDialog(context, card),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.front,
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.frontSubtext != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.frontSubtext!,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        card.back,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Sửa'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: context.colors.error),
                          const SizedBox(width: 8),
                          Text('Xóa',
                              style: TextStyle(color: context.colors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCardDialog(context, card);
                    } else if (value == 'delete') {
                      showDeleteFlashcardDialog(context, card, deckId: deckId);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCardDialog(BuildContext context, FlashcardCard card) {
    context
        .push('/flashcards/$deckId/cards/${card.id}/edit', extra: card)
        .then((_) {
      if (!context.mounted) return;
      context.read<FlashcardProvider>().loadDeckById(deckId);
    });
  }
}
