import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../../config/theme.dart';
import 'vocabulary_detail_screen.dart';
import 'flashcard_study_screen.dart';

class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyProvider>().loadVocabularies(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Từ vựng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLevelFilter(),
          _buildFlashcardButton(),
          Expanded(child: _buildVocabularyList()),
        ],
      ),
    );
  }

  /// Flashcard study button
  Widget _buildFlashcardButton() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        final count = provider.vocabularies.length;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.dynamic_feed, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Học Flashcard ($count từ)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Search bar hiện đại
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            context.read<VocabularyProvider>().searchVocabularies(value);
          }
        },
      ),
    );
  }

  /// Level filter chips
  Widget _buildLevelFilter() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả',
                  isSelected: provider.selectedLevel == null,
                  onTap: () => provider.filterByLevel(null),
                ),
                const SizedBox(width: 8),
                ..._levels.map((level) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: level,
                        isSelected: provider.selectedLevel == level,
                        onTap: () => provider.filterByLevel(level),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
                )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Danh sách từ vựng
  Widget _buildVocabularyList() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.vocabularies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Có lỗi xảy ra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.loadVocabularies(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.vocabularies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có từ vựng nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.vocabularies.length,
                itemBuilder: (context, index) {
                  final vocab = provider.vocabularies[index];
                  return _buildVocabularyCard(vocab);
                },
              ),
            ),
            _buildPagination(),
          ],
        );
      },
    );
  }

  /// Card từ vựng đẹp
  Widget _buildVocabularyCard(vocab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VocabularyDetailScreen(vocabularyId: vocab.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Từ Kanji
                      Text(
                        vocab.word,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Hiragana
                      Text(
                        vocab.hiragana,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Nghĩa
                      Text(
                        vocab.meaning,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Level badge
                if (vocab.level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(vocab.level!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vocab.level!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pagination
  Widget _buildPagination() {
    return Consumer<VocabularyProvider>(
      builder: (context, provider, _) {
        if (provider.totalPages <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: provider.hasPrevPage ? provider.previousPage : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Trước'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'Trang ${provider.currentPage}/${provider.totalPages}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              ElevatedButton.icon(
                onPressed: provider.hasNextPage ? provider.nextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Sau'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    // TODO: Implement advanced filter dialog
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N5':
        return Colors.green;
      case 'N4':
        return Colors.blue;
      case 'N3':
        return Colors.orange;
      case 'N2':
        return Colors.deepOrange;
      case 'N1':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
