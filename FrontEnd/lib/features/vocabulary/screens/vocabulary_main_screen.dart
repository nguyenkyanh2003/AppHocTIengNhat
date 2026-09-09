import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../core/audio/audio_service.dart';
import '../../flashcards/providers/flashcard_provider.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../../flashcards/widgets/flashcard_decks_tab.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/vocabulary_filter_bar.dart';
import '../widgets/vocabulary_list_view.dart';

/// Màn từ vựng: tab danh sách và tab bộ thẻ của người dùng.
class VocabularyMainScreen extends StatefulWidget {
  const VocabularyMainScreen({super.key});

  @override
  State<VocabularyMainScreen> createState() => _VocabularyMainScreenState();
}

class _VocabularyMainScreenState extends State<VocabularyMainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

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

  /// Làm mới đúng tab đang mở, không nạp lại cả hai.
  Future<void> _refreshCurrentTab() {
    if (_tabController.index == 0) {
      return context.read<VocabularyProvider>().loadVocabularies(refresh: true);
    }
    return context.read<FlashcardProvider>().loadDecks(refresh: true);
  }

  Future<void> _createDeck() async {
    final provider = context.read<FlashcardProvider>();
    final created = await context.push<bool>('/flashcards/new');

    if (created == true) await provider.loadDecks(refresh: true);
  }

  void _openDetail(Vocabulary vocabulary) {
    context.push('/vocabulary/${vocabulary.id}');
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
    return AppScaffold(
      title: 'Từ vựng',
      // Tab thuộc khung trang nên do `AppScaffold` dựng; vùng cuộn của mỗi
      // tab vẫn thuộc về chính tab đó.
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Danh sách'),
          Tab(text: 'Bộ thẻ của tôi'),
        ],
      ),
      onRefresh: _refreshCurrentTab,
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
            // Bộ lọc và nút học dùng chung bề rộng với danh sách bên dưới,
            // nếu không thì trên màn rộng chúng chạy dài hơn hẳn các thẻ.
            ContentPane(
              padding: EdgeInsets.zero,
              child: VocabularyFilterBar(
                selectedLevel: provider.selectedLevel,
                onSearch: provider.searchVocabularies,
                onLevelChanged: provider.filterByLevel,
                onClear: provider.resetFilter,
              ),
            ),
            if (items.isNotEmpty)
              ContentPane(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      Uri(
                        path: '/vocabulary/study',
                        queryParameters: provider.selectedLevel == null
                            ? null
                            : {'level': provider.selectedLevel},
                      ).toString(),
                      extra: items,
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
                isLoadingMore: provider.isLoadingMore,
                loadMoreError: provider.loadMoreError,
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
