import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notebook_provider.dart';
import '../../config/theme.dart';
import 'notebook_form_screen.dart';

class NotebookDetailScreen extends StatefulWidget {
  final String noteId;

  const NotebookDetailScreen({Key? key, required this.noteId}) : super(key: key);

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotebookProvider>().loadNoteDetail(widget.noteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ghi chú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: Consumer<NotebookProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
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
                    onPressed: () => provider.loadNoteDetail(widget.noteId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final note = provider.selectedNote;
          if (note == null) {
            return const Center(child: Text('Không tìm thấy ghi chú'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTypeColor(note.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getTypeLabel(note.type),
                    style: TextStyle(
                      color: _getTypeColor(note.type),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Cập nhật: ${_formatDateTime(note.updatedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Tags
                if (note.tags.isNotEmpty) ...[
                  const Text(
                    'Thẻ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: note.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotebookFormScreen(noteId: widget.noteId),
      ),
    ).then((_) {
      context.read<NotebookProvider>().loadNoteDetail(widget.noteId);
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteNote();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote() async {
    final provider = context.read<NotebookProvider>();
    final success = await provider.deleteNote(widget.noteId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa ghi chú'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
