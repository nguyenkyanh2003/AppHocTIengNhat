import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../models/news.dart';
import './news_detail_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin Tức'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              setState(() => _showBookmarks = !_showBookmarks);
            },
          ),
        ],
      ),
      body: Column(
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

                if (provider.isLoading && newsList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (newsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _showBookmarks
                              ? 'Chưa có tin tức yêu thích'
                              : 'Không có tin tức nào',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
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
                    itemCount: newsList.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == newsList.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final news = newsList[index];
                      return _buildNewsCard(context, news, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
          fillColor: Colors.grey[200],
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
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNewsCard(
      BuildContext context, News news, NewsProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(newsId: news.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with consistent aspect ratio
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48),
                      );
                    },
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer: Level, Views, Time, Bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (news.level != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: news.level == 'N5'
                                    ? Colors.green
                                    : news.level == 'N4'
                                        ? Colors.lightGreen
                                        : news.level == 'N3'
                                            ? Colors.amber
                                            : news.level == 'N2'
                                                ? Colors.orange
                                                : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.level!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.visibility,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${news.views}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            news.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          provider.isBookmarked(news.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: provider.isBookmarked(news.id)
                              ? Colors.red
                              : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          provider.toggleBookmark(news.id);
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
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
