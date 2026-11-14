import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/notebook.dart';
import '../providers/notebook_provider.dart';
import '../widgets/notebook_type_badge.dart';

class NotebookDetailScreen extends StatefulWidget {
  const NotebookDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(NotebookDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) _load();
  }

  Future<void> _load() => context.read<NotebookProvider>().loadDetail(widget.noteId);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotebookProvider>().detailOf(widget.noteId);
    return AppScaffold(
      title: 'Chi tiết ghi chú',
      actions: [
        if (state.hasData) ...[
          // Lưu xong provider tự cập nhật chi tiết đang mở, nên không cần tải lại.
          IconButton(
            tooltip: 'Sửa ghi chú',
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/notebook/${widget.noteId}/edit'),
          ),
          IconButton(tooltip: 'Xóa ghi chú', icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ],
      ],
      body: ContentWidthLimit(
        child: AsyncView<Notebook>(
          state: state,
          onRetry: _load,
          builder: (context, note) => _NoteView(note: note),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context.read<NotebookProvider>().delete(widget.noteId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Đã xóa ghi chú'),
      backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
    ));
    if (error == null) Navigator.pop(context);
  }
}

class _NoteView extends StatelessWidget {
  const _NoteView({required this.note});

  final Notebook note;

  @override
  Widget build(BuildContext context) {
    final updated = note.updatedAt;
    final time = '${updated.day}/${updated.month}/${updated.year} '
        '${updated.hour}:${updated.minute.toString().padLeft(2, '0')}';
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotebookTypeBadge(type: note.type),
          const SizedBox(height: AppSpacing.lg),
          Text(note.title, style: const TextStyle(fontSize: AppTypography.headline, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Cập nhật: $time',
                  style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: AppSpacing.page,
            decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: AppRadius.mdAll),
            child: Text(note.content, style: const TextStyle(fontSize: AppTypography.body, height: 1.5)),
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const Text('Thẻ', style: TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in note.tags)
                  Chip(label: Text(tag), backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
