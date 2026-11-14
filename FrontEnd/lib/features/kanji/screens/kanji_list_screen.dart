import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/kanji.dart';
import '../providers/kanji_provider.dart';
import '../widgets/kanji_list_card.dart';

class KanjiListScreen extends StatefulWidget {
  const KanjiListScreen({super.key});

  @override
  State<KanjiListScreen> createState() => _KanjiListScreenState();
}

class _KanjiListScreenState extends State<KanjiListScreen> {
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KanjiProvider>().loadKanjis();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KanjiProvider>();
    return AppScaffold(
      title: 'Kanji',
      body: ContentWidthLimit(
        child: Column(
          children: [
            _searchBar(provider),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                children: [
                  _LevelChip(label: 'Tất cả', selected: provider.selectedLevel == null, onTap: () => provider.filterByLevel(null)),
                  for (final level in _levels)
                    _LevelChip(
                      label: level,
                      selected: provider.selectedLevel == level,
                      onTap: () => provider.filterByLevel(level),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<Kanji>>(
                state: provider.kanjis,
                onRetry: provider.loadKanjis,
                isEmpty: (kanjis) => kanjis.isEmpty,
                emptyTitle: 'Không tìm thấy Kanji nào',
                emptyIcon: Icons.search_off,
                builder: (context, kanjis) => PagedListView<Kanji>(
                  items: kanjis,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  hasMore: provider.hasMore,
                  isLoadingMore: provider.isLoadingMore,
                  loadMoreError: provider.loadMoreError,
                  onLoadMore: provider.loadMore,
                  itemBuilder: (context, kanji) => KanjiListCard(kanji: kanji),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tìm khi bấm Enter (không tìm theo từng phím gõ); xoá ô là về danh sách.
  Widget _searchBar(KanjiProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.lgAll,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm Kanji...',
            hintStyle: TextStyle(color: context.colors.textDisabled),
            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xoá từ khoá',
                    icon: Icon(Icons.clear, color: context.colors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      provider.search('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: AppSpacing.page,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty && provider.searchQuery.isNotEmpty) provider.search('');
          },
          onSubmitted: provider.search,
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
        backgroundColor: context.colors.surface,
        selectedColor: AppColors.kanjiCoral.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected ? context.colors.readable(AppColors.kanjiCoral) : context.colors.textSecondary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: selected ? AppColors.kanjiCoral : context.colors.border, width: selected ? 2 : 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}
