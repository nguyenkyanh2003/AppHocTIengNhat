import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/network/api_envelope.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/admin_content_type.dart';
import '../providers/admin_content_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_content_actions.dart';
import '../widgets/admin_content_card.dart';
import '../widgets/admin_content_editor.dart';
import '../widgets/admin_content_stats.dart';
import '../widgets/admin_content_table.dart';
import '../widgets/admin_content_type_selector.dart';

/// Quản lý từ vựng, Kanji, ngữ pháp và bài học. [service] chỉ để test truyền
/// service giả.
class AdminContentManagementScreen extends StatelessWidget {
  const AdminContentManagementScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminContentProvider(service: service)..load(),
      child: const _ContentView(),
    );
  }
}

class _ContentView extends StatefulWidget {
  const _ContentView();

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lọc nhanh trên các mục đã tải: API danh sách của từ vựng và Kanji không
  /// nhận từ khoá.
  List<JsonObject> _matching(List<JsonObject> items) {
    final search = _searchController.text.trim().toLowerCase();
    if (search.isEmpty) return items;
    return [
      for (final item in items)
        if (item.values.any((value) => '$value'.toLowerCase().contains(search))) item,
    ];
  }

  void _selectType(AdminContentProvider provider, AdminContentType type) {
    _searchController.clear();
    provider.selectType(type);
  }

  void _onAction(AdminContentAction action, JsonObject item) => switch (action) {
        AdminContentAction.edit => showAdminContentEditor(context, item: item),
        AdminContentAction.duplicate => showAdminContentEditor(context, item: item, duplicate: true),
        AdminContentAction.delete => confirmDeleteAdminContent(context, item),
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminContentProvider>();
    final type = provider.type;
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final visible = _matching(provider.items.valueOrNull ?? const []);

    return AppScaffold(
      title: 'Quản lý nội dung',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: provider.load, tooltip: 'Làm mới'),
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: provider.isImporting ? null : () => showAdminContentImportDialog(context),
          tooltip: 'Import dữ liệu',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => exportAdminContent(context, visible),
          tooltip: 'Xuất CSV',
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            AdminContentTypeSelector(selected: type, onSelect: (value) => _selectType(provider, value)),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Lọc ${type.label.toLowerCase()} đã tải...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: hasSearch
                      ? IconButton(
                          tooltip: 'Xoá bộ lọc',
                          onPressed: () => setState(_searchController.clear),
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            AdminContentStats(content: visible),
            if (provider.isImporting || provider.isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: AsyncView<List<JsonObject>>(
                state: provider.items.map(_matching),
                onRetry: provider.load,
                isEmpty: (items) => items.isEmpty,
                emptyTitle: 'Không có ${type.label.toLowerCase()}',
                builder: (context, items) => AdaptiveTable<JsonObject>(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  items: items,
                  onRefresh: provider.load,
                  rowKey: (item) => ValueKey(item['_id']),
                  columns: adminContentColumns(type, onAction: _onAction),
                  cardBuilder: (context, item) => AdminContentCard(item: item, type: type, onAction: _onAction),
                  paging: TablePaging(
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    error: provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAdminContentEditor(context),
        icon: const Icon(Icons.add),
        label: Text('Thêm ${type.label}'),
      ),
    );
  }
}
