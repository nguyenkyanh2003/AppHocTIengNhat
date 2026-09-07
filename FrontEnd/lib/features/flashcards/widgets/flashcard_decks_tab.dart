import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';
import '../screens/flashcard_deck_detail_screen.dart';
import '../screens/flashcard_study_screen.dart';

/// Danh sách bộ thẻ của người dùng.
///
/// Nằm trong feature `flashcards` vì nó sở hữu model, provider và điều hướng
/// của bộ thẻ; màn từ vựng chỉ nhúng widget này vào một tab.
class FlashcardDecksTab extends StatelessWidget {
  const FlashcardDecksTab({super.key, required this.onCreateDeck});

  final Future<void> Function() onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.decks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.decks.isEmpty) {
          return ErrorStateView(
            message: provider.error!,
            onRetry: () => provider.loadDecks(refresh: true),
          );
        }

        if (provider.decks.isEmpty) {
          return EmptyStateView(
            title: 'Chưa có bộ thẻ nào',
            message: 'Tạo bộ thẻ để học từ vựng theo cách riêng của bạn.',
            icon: Icons.style_outlined,
            action: FilledButton.icon(
              onPressed: onCreateDeck,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ thẻ đầu tiên'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDecks(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemCount: provider.decks.length,
            itemBuilder: (context, index) =>
                _DeckCard(deck: provider.decks[index]),
          ),
        );
      },
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck});

  final FlashcardDeck deck;

  int get _cardCount => deck.cards.isNotEmpty ? deck.cards.length : deck.totalCards;

  Future<void> _openDetail(BuildContext context) async {
    final provider = context.read<FlashcardProvider>();
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardDeckDetailScreen(deckId: deck.id),
      ),
    );

    if (changed == true) await provider.loadDecks(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: () => _openDetail(context),
      accent: AppColors.vocabulary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style, color: AppColors.vocabulary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.title,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('$_cardCount thẻ', style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (_cardCount > 0)
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardStudyScreen(flashcardDeck: deck),
                    ),
                  ),
                  child: const Text('Học'),
                ),
            ],
          ),
          if (deck.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              deck.description!,
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Đã học ${deck.studyCount} lần', style: textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
