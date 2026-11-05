import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/notebook_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../widgets/notebook_note_card.dart';
import '../widgets/notebook_pagination.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/notebook.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({Key? key}) : super(key: key);

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotebookProvider>().loadNotes(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sổ tay',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<NotebookProvider>(
          builder: (context, provider, child) {
            return AsyncView<List<Notebook>>(
              state: ViewState.fromLegacy(
                isLoading: provider.isLoading,
                error: provider.error,
                value: provider.notes,
                isEmpty: provider.notes.isEmpty,
              ),
              onRetry: () => provider.loadNotes(refresh: true),
              isEmpty: (notes) => notes.isEmpty,
              emptyTitle: 'Chưa có ghi chú nào',
              emptyMessage: 'Nhấn + để tạo ghi chú mới',
              emptyIcon: Icons.note_add,
              builder: (context, notes) => RefreshIndicator(
                onRefresh: () => provider.loadNotes(refresh: true),
                child: Column(
                  children: [
                    if (provider.selectedType != null ||
                        provider.searchQuery.isNotEmpty)
                      _buildFilterChips(provider),
                    Expanded(
                      child: ListView.builder(
                        itemCount: notes.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => NotebookNoteCard(
                            note: notes[index], getTypeLabel: _getTypeLabel),
                      ),
                    ),
                    if (provider.totalPages > 1)
                      NotebookPagination(provider: provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppTheme.notebookColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(NotebookProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (provider.searchQuery.isNotEmpty)
            Chip(
              label: Text('Tìm: ${provider.searchQuery}'),
              onDeleted: () {
                _searchController.clear();
                provider.searchNotes('');
              },
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (provider.selectedType != null)
            Chip(
              label: Text(_getTypeLabel(provider.selectedType!)),
              onDeleted: () => provider.filterByType(null),
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm ghi chú'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            context.read<NotebookProvider>().searchNotes(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<NotebookProvider>()
                  .searchNotes(_searchController.text);
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo loại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Tất cả', null),
            _buildFilterOption('Chung', 'general'),
            _buildFilterOption('Từ vựng', 'vocabulary'),
            _buildFilterOption('Ngữ pháp', 'grammar'),
            _buildFilterOption('Kanji', 'kanji'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String? type) {
    return RadioListTile<String?>(
      title: Text(label),
      value: type,
      groupValue: _selectedType,
      onChanged: (value) {
        setState(() => _selectedType = value);
        Navigator.pop(context);
        context.read<NotebookProvider>().filterByType(value);
      },
    );
  }

  void _navigateToForm({String? noteId}) {
    final path = noteId == null ? '/notebook/new' : '/notebook/$noteId/edit';
    context.push(path).then((_) {
      if (!mounted) return;
      context.read<NotebookProvider>().loadNotes(refresh: true);
    });
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vocabulary':
        return 'Từ vựng';
      case 'grammar':
        return 'Ngữ pháp';
      case 'kanji':
        return 'Kanji';
      default:
        return 'Chung';
    }
  }
}
