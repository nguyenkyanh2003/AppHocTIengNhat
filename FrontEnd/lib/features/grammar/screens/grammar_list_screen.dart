import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/grammar.dart';
import '../providers/grammar_provider.dart';
import '../widgets/grammar_card.dart';

class GrammarListScreen extends StatefulWidget {
  const GrammarListScreen({super.key, this.level});

  final String? level;

  @override
  State<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends State<GrammarListScreen> {
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
  static const _sorts = {GrammarSort.popular: 'Phổ biến', GrammarSort.newest: 'Mới nhất'};

  final _searchController = TextEditingController();
  late String _level = widget.level ?? 'N5';
  GrammarSort _sort = GrammarSort.popular;

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

  /// Có từ khoá thì tìm trên mọi cấp độ, không thì liệt kê cấp độ đang chọn.
  Future<void> _load() {
    final search = _searchController.text.trim();
    return context.read<GrammarProvider>().load(
          level: search.isEmpty ? _level : null,
          search: search.isEmpty ? null : search,
          sort: search.isEmpty ? _sort : GrammarSort.title,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GrammarProvider>();
    return AppScaffold(
      title: 'Ngữ Pháp',
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm ngữ pháp...',
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
                      border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _load();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _level,
                          isExpanded: true,
                          items: [for (final level in _levels) DropdownMenuItem(value: level, child: Text(level))],
                          onChanged: (value) {
                            setState(() => _level = value ?? _level);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButton<GrammarSort>(
                          value: _sort,
                          isExpanded: true,
                          items: [
                            for (final MapEntry(key: sort, value: label) in _sorts.entries)
                              DropdownMenuItem(value: sort, child: Text(label)),
                          ],
                          onChanged: (value) {
                            setState(() => _sort = value ?? _sort);
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<Grammar>>(
                state: provider.listState,
                onRetry: _load,
                isEmpty: (grammars) => grammars.isEmpty,
                emptyTitle: 'Không tìm thấy ngữ pháp',
                builder: (context, grammars) => PagedListView<Grammar>(
                  items: grammars,
                  padding: AppSpacing.pageHorizontal,
                  hasMore: provider.hasMore,
                  isLoadingMore: provider.isLoadingMore,
                  loadMoreError: provider.loadMoreError,
                  onLoadMore: provider.loadMore,
                  itemBuilder: (context, grammar) =>
                      GrammarCard(grammar: grammar, onTap: () => context.push('/grammar/${grammar.id}')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
