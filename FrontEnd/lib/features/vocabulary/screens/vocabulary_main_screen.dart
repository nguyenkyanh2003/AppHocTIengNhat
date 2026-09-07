import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/audio/audio_service.dart';
import '../../flashcards/providers/flashcard_provider.dart';
import '../../flashcards/screens/create_flashcard_deck_screen.dart';
import '../../flashcards/screens/flashcard_study_screen.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../../flashcards/widgets/flashcard_decks_tab.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/vocabulary_filter_bar.dart';
import '../widgets/vocabulary_list_view.dart';
import 'vocabulary_detail_screen.dart';

/// Màn từ vựng: tab danh sách và tab bộ thẻ của người dùng.
class VocabularyMainScreen extends StatefulWidget {
  const VocabularyMainScreen({super.key});

  @override
  State<VocabularyMainScreen> createState() => _VocabularyMainScreenState();
}

class _VocabularyMainScreenState extends State<VocabularyMainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VocabularyProvider>().loadVocabularies(refresh: true);
      context.read<FlashcardProvider>().loadDecks(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createDeck() async {
    final provider = context.read<FlashcardProvider>();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFlashcardDeckScreen()),
    );

    if (created == true) await provider.loadDecks(refresh: true);
  }

  void _openDetail(Vocabulary vocabulary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyDetailScreen(vocabularyId: vocabulary.id),
      ),
    );
  }

  void _addToFlashcard(Vocabulary vocabulary) {
    AddToFlashcardDialog.show(
      context,
      front: vocabulary.word,
      back: vocabulary.meaning,
      frontSubtext: vocabulary.hiragana,
    );
  }

  Future<void> _play(Vocabulary vocabulary) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AudioService().playAudio(vocabulary.audioUrl!);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không phát được âm thanh.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Danh sách'),
            Tab(text: 'Bộ thẻ của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VocabularyListTab(
            onOpen: _openDetail,
            onAddToFlashcard: _addToFlashcard,
            onPlayAudio: _play,
          ),
          FlashcardDecksTab(onCreateDeck: _createDeck),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _createDeck,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ thẻ'),
            )
          : null,
    );
  }
}

class _VocabularyListTab extends StatelessWidget {
  const _VocabularyListTab({
    required this.onOpen,
    required this.onAddToFlashcard,
    required this.onPlayAudio,
  });

  final void Function(Vocabulary vocabulary) onOpen;
  final void Function(Vocabulary vocabulary) onAddToFlashcard;
  final Future<void> Function(Vocabulary vocabulary) onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        final items = provider.vocabularies;

        return Column(
          children: [
            VocabularyFilterBar(
              selectedLevel: provider.selectedLevel,
              onSearch: provider.searchVocabularies,
              onLevelChanged: provider.filterByLevel,
              onClear: provider.resetFilter,
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlashcardStudyScreen(
                          level: provider.selectedLevel,
                          vocabularies: items,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Học Flashcard (${items.length} từ)'),
                  ),
                ),
              ),
            Expanded(
              child: VocabularyListView(
                state: provider.listState,
                hasNextPage: provider.hasNextPage,
                onRefresh: () => provider.loadVocabularies(refresh: true),
                onLoadMore: provider.loadMore,
                onOpen: onOpen,
                onAddToFlashcard: onAddToFlashcard,
                onPlayAudio: onPlayAudio,
              ),
            ),
          ],
        );
      },
    );
  }
}
