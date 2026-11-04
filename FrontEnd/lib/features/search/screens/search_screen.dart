import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/search_result.dart';
import '../providers/search_provider.dart';
import '../services/search_service.dart';
import '../widgets/search_result_list.dart';

/// Tìm kiếm chung trên từ vựng, Kanji, bài học, ngữ pháp và tin tức.
///
/// Provider tạo cùng màn và huỷ khi rời màn, nên mỗi lần mở là một ô trống và
/// không còn hẹn giờ hay request nào chạy sau khi rời. [service] chỉ để test
/// truyền service giả.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.service});

  final SearchService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(service: service),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear(SearchProvider provider) {
    _controller.clear();
    provider.clear();
  }

  static String _detailPath(SearchResult result) => switch (result.type) {
        SearchResultType.vocabulary => '/vocabulary/${result.id}',
        SearchResultType.kanji => '/kanji/${result.id}',
        SearchResultType.lesson => '/lessons/${result.id}',
        SearchResultType.grammar => '/grammar/${result.id}',
        SearchResultType.news => '/news/${result.id}',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return AppScaffold(
      title: 'Tìm kiếm',
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page,
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: provider.updateQuery,
                decoration: InputDecoration(
                  hintText: 'Tìm từ vựng, Kanji, bài học, ngữ pháp, tin tức…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Xoá từ khoá',
                            icon: const Icon(Icons.clear),
                            onPressed: () => _clear(provider),
                          ),
                  ),
                ),
              ),
            ),
            Expanded(child: _results(provider)),
          ],
        ),
      ),
    );
  }

  Widget _results(SearchProvider provider) {
    if (provider.query.isEmpty) {
      return const EmptyStateView(
        title: 'Tìm trong toàn bộ nội dung',
        message: 'Gõ chữ Nhật, cách đọc hoặc nghĩa tiếng Việt — ví dụ 月, つき, mặt trăng.',
        icon: Icons.search,
      );
    }

    return AsyncView<List<SearchResult>>(
      state: provider.results,
      onRetry: provider.retry,
      isEmpty: (results) => results.isEmpty,
      emptyTitle: 'Không tìm thấy kết quả',
      emptyMessage: 'Không có nội dung nào khớp với “${provider.query}”.',
      emptyIcon: Icons.search_off,
      builder: (context, results) => SearchResultList(
        results: results,
        onOpen: (result) => context.push(_detailPath(result)),
      ),
    );
  }
}
