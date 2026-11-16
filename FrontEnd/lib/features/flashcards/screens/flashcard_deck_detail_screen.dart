import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_card_item.dart';
import '../widgets/flashcard_deck_dialogs.dart';
import '../widgets/flashcard_deck_header.dart';

class FlashcardDeckDetailScreen extends StatefulWidget {
  const FlashcardDeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<FlashcardDeckDetailScreen> createState() => _FlashcardDeckDetailScreenState();
}

class _FlashcardDeckDetailScreenState extends State<FlashcardDeckDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(FlashcardDeckDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deckId != widget.deckId) _load();
  }

  Future<void> _load() => context.read<FlashcardProvider>().loadDetail(widget.deckId);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FlashcardProvider>().detailOf(widget.deckId);
    final deck = state.valueOrNull;
    return AppScaffold(
      title: 'Chi Tiết Bộ Thẻ',
      actions: [
        if (deck != null) ...[
          IconButton(
            tooltip: 'Sửa bộ thẻ',
            icon: const Icon(Icons.edit),
            onPressed: () => showEditFlashcardDeckDialog(context, deck),
          ),
          IconButton(
            tooltip: 'Xóa bộ thẻ',
            icon: const Icon(Icons.delete),
            onPressed: () => showDeleteFlashcardDeckDialog(context, deckId: deck.id),
          ),
        ],
      ],
      body: ContentWidthLimit(
        child: AsyncView<FlashcardDeck>(
          state: state,
          onRetry: _load,
          builder: (context, deck) => Column(
            children: [
              FlashcardDeckHeader(deck: deck),
              Expanded(child: _CardList(deck: deck)),
            ],
          ),
        ),
      ),
      // Lưu thẻ xong provider tự cập nhật bộ đang mở, nên không cần tải lại khi quay về.
      floatingActionButton: deck == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/flashcards/${deck.id}/cards/new'),
              icon: const Icon(Icons.add),
              label: const Text('Thêm Thẻ'),
            ),
      backgroundColor: context.colors.surfaceVariant,
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.deck});

  final FlashcardDeck deck;

  @override
  Widget build(BuildContext context) {
    if (deck.cards.isEmpty) {
      return const EmptyStateView(
        title: 'Chưa có thẻ nào',
        message: 'Thêm thẻ đầu tiên của bạn!',
        icon: Icons.style_outlined,
      );
    }
    return ListView.builder(
      padding: AppSpacing.page,
      itemCount: deck.cards.length,
      itemBuilder: (context, index) => FlashcardCardItem(card: deck.cards[index], index: index, deckId: deck.id),
    );
  }
}
