import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../../vocabulary/screens/vocabulary_detail_screen.dart';
import '../../kanji/screens/kanji_detail_screen.dart';
import '../../grammar/screens/grammar_detail_screen.dart';
import '../services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, SearchResult result) {
    switch (result.type) {
      case 'vocabulary':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VocabularyDetailScreen(vocabularyId: result.id),
          ),
        );
        break;
      case 'kanji':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KanjiDetailScreen(kanjiId: result.id),
          ),
        );
        break;
      case 'grammar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarDetailScreen(grammarId: result.id),
          ),
        );
        break;
      // Add other types as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Kiếm'),
        elevation: 0,
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm từ vựng, kanji, bài học...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    provider.search(value);
                  },
                ),
              ),

              // Results
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(
                            child: Text(provider.error ?? ''),
                          )
                        : provider.searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'Nhập từ khóa để tìm kiếm'
                                          : 'Không tìm thấy kết quả',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: provider.searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = provider.searchResults[index];
                                  return _buildSearchResultCard(
                                    context,
                                    result,
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () => _navigateToDetail(context, result),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(result.type),
          child: Icon(
            _getTypeIcon(result.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          result.description ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(result.type).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getTypeLabel(result.type),
            style: TextStyle(
              fontSize: 12,
              color: _getTypeColor(result.type),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vocabulary':
        return 'Từ vựng';
      case 'kanji':
        return 'Kanji';
      case 'lesson':
        return 'Bài học';
      case 'grammar':
        return 'Ngữ pháp';
      case 'news':
        return 'Tin tức';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'vocabulary':
        return Icons.spellcheck;
      case 'kanji':
        return Icons.draw_outlined;
      case 'lesson':
        return Icons.menu_book;
      case 'grammar':
        return Icons.school;
      case 'news':
        return Icons.newspaper;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vocabulary':
        return Colors.blue;
      case 'kanji':
        return Colors.red;
      case 'lesson':
        return Colors.purple;
      case 'grammar':
        return Colors.orange;
      case 'news':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
