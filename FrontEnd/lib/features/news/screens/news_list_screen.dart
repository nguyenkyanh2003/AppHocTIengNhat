import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/news.dart';
import '../providers/news_provider.dart';
import '../widgets/news_list_card.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  final _searchController = TextEditingController();
  String? _selectedLevel;
  bool _showBookmarks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() {
    final search = _searchController.text.trim();
    return context.read<NewsProvider>().load(level: _selectedLevel, search: search.isEmpty ? null : search);
  }

  void _selectLevel(String? level) {
    setState(() => _selectedLevel = level);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    // Tin yêu thích lọc trên danh sách đã tải, nên luôn có sẵn, không có nhánh tải hay lỗi.
    final state = _showBookmarks ? ViewState.data(provider.bookmarkedNews) : provider.listState;
    return AppScaffold(
      title: 'Tin Tức',
      actions: [
        IconButton(
          tooltip: _showBookmarks ? 'Xem mọi tin' : 'Tin đã lưu',
          icon: Icon(_showBookmarks ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => setState(() => _showBookmarks = !_showBookmarks),
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                  _load();
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tin tức...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _load();
                          },
                        ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: context.colors.surfaceVariant,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  _LevelChip(label: 'Tất cả', selected: _selectedLevel == null, onTap: () => _selectLevel(null)),
                  for (final level in _levels)
                    _LevelChip(label: level, selected: _selectedLevel == level, onTap: () => _selectLevel(level)),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<News>>(
                state: state,
                onRetry: _load,
                isEmpty: (items) => items.isEmpty,
                emptyTitle: _showBookmarks ? 'Chưa có tin tức yêu thích' : 'Không có tin tức nào',
                emptyIcon: Icons.newspaper,
                builder: (context, items) => RefreshIndicator(
                  onRefresh: provider.refresh,
                  // Tin đã lưu lọc trên danh sách đang có, nên không có trang sau.
                  child: PagedListView<News>(
                    items: items,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    hasMore: !_showBookmarks && provider.hasMore,
                    isLoadingMore: !_showBookmarks && provider.isLoadingMore,
                    loadMoreError: _showBookmarks ? null : provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                    loadMoreExtent: 500,
                    itemBuilder: (context, news) => NewsListCard(news: news, provider: provider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: context.colors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
