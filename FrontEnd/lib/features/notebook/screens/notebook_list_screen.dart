import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/notebook.dart';
import '../providers/notebook_provider.dart';
import '../widgets/notebook_note_card.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotebookProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotebookProvider>();
    final filtered = provider.selectedType != null || provider.searchQuery.isNotEmpty;
    return AppScaffold(
      title: 'Sổ tay',
      actions: [
        IconButton(tooltip: 'Tìm ghi chú', icon: const Icon(Icons.search), onPressed: _showSearchDialog),
        IconButton(tooltip: 'Lọc theo loại', icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            // Bộ lọc nằm ngoài AsyncView: kết quả rỗng vẫn còn chỗ bỏ lọc.
            if (filtered) _filterChips(provider),
            Expanded(
              child: AsyncView<List<Notebook>>(
                state: provider.notes,
                onRetry: provider.loadNotes,
                isEmpty: (notes) => notes.isEmpty,
                emptyTitle: filtered ? 'Không có ghi chú nào khớp bộ lọc' : 'Chưa có ghi chú nào',
                emptyMessage: filtered ? 'Thử bỏ bớt bộ lọc ở trên.' : 'Nhấn + để tạo ghi chú mới',
                emptyIcon: Icons.note_add,
                builder: (context, notes) => RefreshIndicator(
                  onRefresh: provider.loadNotes,
                  child: PagedListView<Notebook>(
                    items: notes,
                    padding: AppSpacing.page,
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    loadMoreError: provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                    itemBuilder: (context, note) => NotebookNoteCard(note: note),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Lưu xong provider tự tải lại danh sách, nên không cần chờ form đóng.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tạo ghi chú',
        onPressed: () => context.push('/notebook/new'),
        backgroundColor: AppTheme.notebookColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChips(NotebookProvider provider) {
    final type = provider.selectedType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (provider.searchQuery.isNotEmpty)
              InputChip(
                label: Text('Tìm: ${provider.searchQuery}'),
                onDeleted: () {
                  _searchController.clear();
                  provider.searchNotes('');
                },
              ),
            if (type != null) InputChip(label: Text(type.label), onDeleted: () => provider.filterByType(null)),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    _searchController.text = context.read<NotebookProvider>().searchQuery;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void search() {
          Navigator.pop(dialogContext);
          context.read<NotebookProvider>().searchNotes(_searchController.text);
        }

        return AlertDialog(
          title: const Text('Tìm kiếm ghi chú'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Nhập từ khóa...', prefixIcon: Icon(Icons.search)),
            autofocus: true,
            onSubmitted: (_) => search(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            ElevatedButton(onPressed: search, child: const Text('Tìm')),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    final provider = context.read<NotebookProvider>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Widget option(String label, NoteType? type) => ListTile(
              title: Text(label),
              trailing: provider.selectedType == type ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(dialogContext);
                provider.filterByType(type);
              },
            );

        return SimpleDialog(
          title: const Text('Lọc theo loại'),
          children: [
            option('Tất cả', null),
            for (final type in NoteType.values) option(type.label, type),
          ],
        );
      },
    );
  }
}
