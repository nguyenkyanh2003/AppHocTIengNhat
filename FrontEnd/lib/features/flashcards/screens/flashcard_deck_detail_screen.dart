import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/flashcard_deck_dialogs.dart';
import '../widgets/flashcard_deck_header.dart';
import '../widgets/flashcard_card_item.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class FlashcardDeckDetailScreen extends StatefulWidget {
  final String deckId;

  const FlashcardDeckDetailScreen({
    Key? key,
    required this.deckId,
  }) : super(key: key);

  @override
  State<FlashcardDeckDetailScreen> createState() =>
      _FlashcardDeckDetailScreenState();
}

class _FlashcardDeckDetailScreenState extends State<FlashcardDeckDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadDeckById(widget.deckId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chi Tiết Bộ Thẻ',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () =>
              showEditFlashcardDeckDialog(context, deckId: widget.deckId),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () =>
              showDeleteFlashcardDeckDialog(context, deckId: widget.deckId),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<FlashcardProvider>(
          builder: (context, provider, _) {
            final deck = provider.selectedDeck;
            if (deck == null) {
              return AsyncView<FlashcardDeck>(
                state: ViewState.detail(
                  isLoading: provider.isLoading,
                  error: provider.error,
                  value: deck,
                ),
                onRetry: () async {
                  await provider.loadDeckById(widget.deckId);
                },
                builder: (context, _) => const SizedBox.shrink(),
              );
            }

            return Column(
              children: [
                FlashcardDeckHeader(deck: deck),
                Expanded(child: _buildCardsList(deck)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Thẻ'),
        backgroundColor: AppTheme.primaryColor,
      ),
      backgroundColor: context.colors.surfaceVariant,
    );
  }

  Widget _buildCardsList(FlashcardDeck deck) {
    if (deck.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 80, color: context.colors.border),
            const SizedBox(height: 16),
            Text(
              'Chưa có thẻ nào',
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm thẻ đầu tiên của bạn!',
              style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: context.colors.textDisabled),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deck.cards.length,
      itemBuilder: (context, index) {
        final card = deck.cards[index];
        return FlashcardCardItem(
            card: card, index: index, deckId: widget.deckId);
      },
    );
  }

  void _showAddCardDialog() {
    context
        .push(
      '/flashcards/${widget.deckId}/cards/new',
    )
        .then((_) {
      if (!mounted) return;
      context.read<FlashcardProvider>().loadDeckById(widget.deckId);
    });
  }
}
