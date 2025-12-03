import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notebook_provider.dart';
import '../../models/notebook.dart';
import '../../config/theme.dart';
import 'notebook_form_screen.dart';
import 'notebook_detail_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ tay'),
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
      ),
      body: Consumer<NotebookProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadNotes(refresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (provider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ghi chú nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn + để tạo ghi chú mới',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotes(refresh: true),
            child: Column(
              children: [
                if (provider.selectedType != null || provider.searchQuery.isNotEmpty)
                  _buildFilterChips(provider),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.notes.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final note = provider.notes[index];
                      return _buildNoteCard(note);
                    },
                  ),
                ),
                if (provider.totalPages > 1) _buildPagination(provider),
              ],
            ),
          );
        },
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

  Widget _buildNoteCard(Notebook note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(note.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(note.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeLabel(note.type),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTypeColor(note.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: note.tags.take(3).map<Widget>((tag) {
                    return Chip(
                      label: Text(tag.toString()),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 11),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(NotebookProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: provider.hasPrevPage ? provider.previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          Text(
            'Trang ${provider.currentPage}/${provider.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ElevatedButton.icon(
            onPressed: provider.hasNextPage ? provider.nextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: ElevatedButton.styleFrom(
              iconColor: Colors.white,
            ),
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
              context.read<NotebookProvider>().searchNotes(_searchController.text);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotebookFormScreen(noteId: noteId),
      ),
    ).then((_) {
      context.read<NotebookProvider>().loadNotes(refresh: true);
    });
  }

  void _navigateToDetail(String noteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotebookDetailScreen(noteId: noteId),
      ),
    );
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vocabulary':
        return AppTheme.vocabularyColor;
      case 'grammar':
        return AppTheme.grammarColor;
      case 'kanji':
        return AppTheme.kanjiColor;
      default:
        return AppTheme.notebookColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
