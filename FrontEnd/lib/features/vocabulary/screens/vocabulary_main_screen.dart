import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocabulary_provider.dart';
import '../../flashcards/providers/flashcard_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../models/vocabulary.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import './vocabulary_detail_screen.dart';
import '../../flashcards/screens/flashcard_study_screen.dart';
import '../../flashcards/screens/flashcard_deck_detail_screen.dart';
import '../../flashcards/screens/create_flashcard_deck_screen.dart';

class VocabularyMainScreen extends StatefulWidget {
  const VocabularyMainScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyMainScreen> createState() => _VocabularyMainScreenState();
}

class _VocabularyMainScreenState extends State<VocabularyMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Để FAB cập nhật khi đổi tab
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyProvider>().loadVocabularies(refresh: true);
      context.read<FlashcardProvider>().loadDecks(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Từ vựng'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Danh sách'),
                Tab(text: 'Bộ thẻ của tôi'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVocabularyTab(),
          _buildFlashcardTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _createNewDeck,
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ thẻ'),
            )
          : null,
    );
  }

  Future<void> _createNewDeck() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateFlashcardDeckScreen(),
      ),
    );
    if (result == true && mounted) {
      context.read<FlashcardProvider>().loadDecks(refresh: true);
    }
  }

  // ==================== TAB 1: DANH SÁCH TỪ VỰNG ====================

  Widget _buildVocabularyTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildLevelFilter(),
        _buildFlashcardStudyButton(),
        Expanded(child: _buildVocabularyList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm từ vựng...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<VocabularyProvider>().resetFilter();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            context.read<VocabularyProvider>().searchVocabularies(value);
          }
        },
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              final level = _levels[index];
              final isSelected = provider.selectedLevel == level;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: FilterChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByLevel(selected ? level : null);
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFlashcardStudyButton() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        final count = provider.vocabularies.length;
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardStudyScreen(
                      level: provider.selectedLevel,
                      vocabularies: provider.vocabularies,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Học Flashcard ($count từ)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVocabularyList() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.vocabularies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.vocabularies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy từ vựng',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadVocabularies(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  provider.hasNextPage &&
                  !provider.isLoading) {
                provider.nextPage();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount:
                  provider.vocabularies.length + (provider.hasNextPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.vocabularies.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildVocabularyCard(provider.vocabularies[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVocabularyCard(Vocabulary vocab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VocabularyDetailScreen(vocabularyId: vocab.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Level badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _getLevelColor(vocab.level ?? '').withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    vocab.level ?? '',
                    style: TextStyle(
                      color: _getLevelColor(vocab.level ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vocab.hiragana.isNotEmpty)
                      Text(
                        vocab.hiragana,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    Text(
                      vocab.meaning,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Add to flashcard
              IconButton(
                icon: Icon(Icons.add_card,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                tooltip: 'Thêm vào Flashcard',
                onPressed: () {
                  AddToFlashcardDialog.show(
                    context,
                    front: vocab.word,
                    back: vocab.meaning,
                    frontSubtext: vocab.hiragana,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N5':
        return Colors.green;
      case 'N4':
        return Colors.teal;
      case 'N3':
        return Colors.blue;
      case 'N2':
        return Colors.orange;
      case 'N1':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ==================== TAB 2: BỘ THẺ CỦA TÔI ====================

  Widget _buildFlashcardTab() {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.decks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.decks.isEmpty) {
          return _buildEmptyFlashcardState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDecks(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.decks.length,
            itemBuilder: (context, index) {
              return _buildDeckCard(provider.decks[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyFlashcardState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có bộ thẻ nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo bộ thẻ để học từ vựng\ntheo cách riêng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewDeck,
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ thẻ đầu tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  Widget _buildDeckCard(deck) {
    final cardCount = deck.cards?.length ?? deck.totalCards ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardDeckDetailScreen(deckId: deck.id),
            ),
          );
          if (result == true && mounted) {
            context.read<FlashcardProvider>().loadDecks(refresh: true);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.style, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$cardCount thẻ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (deck.description?.isNotEmpty ?? false)
                          Text(
                            deck.description!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.play_circle_outline,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Đã học ${deck.studyCount ?? 0} lần',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (cardCount > 0)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlashcardStudyScreen(
                              flashcardDeck: deck,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Học'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
