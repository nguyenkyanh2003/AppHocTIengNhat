import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_decks_tab.dart';

/// Danh sách bộ thẻ của người dùng, mở từ ô "Bộ thẻ" ở trang Ôn tập.
class FlashcardDeckListScreen extends StatefulWidget {
  const FlashcardDeckListScreen({super.key});

  @override
  State<FlashcardDeckListScreen> createState() =>
      _FlashcardDeckListScreenState();
}

class _FlashcardDeckListScreenState extends State<FlashcardDeckListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FlashcardProvider>().loadDecks(refresh: true);
    });
  }

  Future<void> _createDeck() async {
    final provider = context.read<FlashcardProvider>();
    final created = await context.push<bool>('/flashcards/new');
    if (created == true) await provider.loadDecks(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bộ thẻ của tôi',
      body: ContentWidthLimit(
        child: FlashcardDecksTab(onCreateDeck: _createDeck),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDeck,
        icon: const Icon(Icons.add),
        label: const Text('Tạo bộ thẻ'),
      ),
    );
  }
}
