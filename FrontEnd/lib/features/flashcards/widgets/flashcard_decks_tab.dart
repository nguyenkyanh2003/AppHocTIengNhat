import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';

/// Danh sách bộ thẻ của người dùng.
///
/// Nằm trong feature `flashcards` vì nó sở hữu model, provider và điều hướng
/// của bộ thẻ; màn từ vựng chỉ nhúng widget này vào một tab.
class FlashcardDecksTab extends StatelessWidget {
  const FlashcardDecksTab({super.key, required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    return AsyncView<List<FlashcardDeck>>(
      state: provider.decks,
      onRetry: provider.loadDecks,
      isEmpty: (decks) => decks.isEmpty,
      emptyTitle: 'Chưa có bộ thẻ nào',
      emptyMessage: 'Tạo bộ thẻ để học từ vựng theo cách riêng của bạn.',
      emptyIcon: Icons.style_outlined,
      emptyAction: FilledButton.icon(
        onPressed: onCreateDeck,
        icon: const Icon(Icons.add),
        label: const Text('Tạo bộ thẻ đầu tiên'),
      ),
      builder: (context, decks) => RefreshIndicator(
        onRefresh: provider.loadDecks,
        child: PagedListView<FlashcardDeck>(
          items: decks,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          hasMore: provider.hasMore,
          isLoadingMore: provider.isLoadingMore,
          loadMoreError: provider.loadMoreError,
          onLoadMore: provider.loadMore,
          itemBuilder: (context, deck) => _DeckCard(deck: deck),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck});

  final FlashcardDeck deck;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = deck.description;

    return AppCard(
      onTap: () => context.push('/flashcards/${deck.id}'),
      accent: AppColors.vocabulary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.title, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${deck.cardCount} thẻ', style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (deck.cardCount > 0)
                FilledButton(
                  onPressed: () => context.push('/flashcards/${deck.id}/study', extra: deck),
                  child: const Text('Học'),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.play_circle_outline, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Đã học ${deck.studyCount} lần', style: textTheme.labelMedium)),
            ],
          ),
        ],
      ),
    );
  }
}
