import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/news_list_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/news.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({Key? key}) : super(key: key);

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedLevel;
  bool _showBookmarks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NewsProvider>(context, listen: false);
      provider.loadNews();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      final provider = Provider.of<NewsProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.loadNews(
          level: _selectedLevel,
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    provider.loadNews(
      refresh: true,
      level: _selectedLevel,
      search: query.isNotEmpty ? query : null,
    );
  }

  void _onLevelChanged(String? level) {
    setState(() => _selectedLevel = level);
    final provider = Provider.of<NewsProvider>(context, listen: false);
    provider.loadNews(
      refresh: true,
      level: level,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tin Tức',
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: () {
            setState(() => _showBookmarks = !_showBookmarks);
          },
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            // Search & Filter
            _buildSearchBar(),

            // Level Filter
            _buildLevelFilter(),

            // News List
            Expanded(
              child: Consumer<NewsProvider>(
                builder: (context, provider, _) {
                  final newsList = _showBookmarks
                      ? provider.bookmarkedNews
                      : provider.newsList;

                  return AsyncView<List<News>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoading,
                      error: _showBookmarks ? null : provider.error,
                      value: newsList,
                      isEmpty: newsList.isEmpty,
                    ),
                    onRetry: () => provider.loadNews(
                      refresh: true,
                      level: _selectedLevel,
                      search: _searchController.text.isNotEmpty
                          ? _searchController.text
                          : null,
                    ),
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: _showBookmarks
                        ? 'Chưa có tin tức yêu thích'
                        : 'Không có tin tức nào',
                    emptyIcon: Icons.newspaper,
                    builder: (context, items) => RefreshIndicator(
                      onRefresh: () => provider.loadNews(
                        refresh: true,
                        level: _selectedLevel,
                        search: _searchController.text.isNotEmpty
                            ? _searchController.text
                            : null,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: items.length + (provider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return NewsListCard(
                              news: items[index], provider: provider);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin tức...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.colors.surfaceVariant,
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip(null, 'Tất cả'),
          ...['N5', 'N4', 'N3', 'N2', 'N1']
              .map((level) => _buildFilterChip(level, level)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? level, String label) {
    final isSelected = _selectedLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onLevelChanged(level),
        backgroundColor: context.colors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
