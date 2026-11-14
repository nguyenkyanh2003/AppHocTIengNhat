import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/notebook.dart';
import '../providers/notebook_provider.dart';
import '../widgets/notebook_tag_editor.dart';
import '../widgets/notebook_type_picker.dart';

/// Tạo ghi chú mới, hoặc sửa ghi chú [noteId] khi có.
class NotebookFormScreen extends StatefulWidget {
  const NotebookFormScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NotebookFormScreen> createState() => _NotebookFormScreenState();
}

class _NotebookFormScreenState extends State<NotebookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  NoteType _type = NoteType.general;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // Sau khung hình đầu: provider không được báo thay đổi khi cây đang dựng.
    if (widget.noteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// Đi từ màn chi tiết thì ghi chú đã có sẵn, không tải lại.
  Future<void> _load() async {
    final id = widget.noteId!;
    final provider = context.read<NotebookProvider>();
    if (!provider.detailOf(id).hasData) await provider.loadDetail(id);
    final note = provider.detailOf(id).valueOrNull;
    if (!mounted || note == null) return;
    _titleController.text = note.title;
    _contentController.text = note.content;
    setState(() {
      _type = note.type;
      _tags
        ..clear()
        ..addAll(note.tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotebookProvider>();
    final id = widget.noteId;
    final ready = id == null || provider.detailOf(id).hasData;
    return AppScaffold(
      title: id == null ? 'Tạo ghi chú mới' : 'Chỉnh sửa ghi chú',
      actions: [
        TextButton(
          onPressed: ready && !provider.isSaving ? _save : null,
          child: const Text('Lưu', style: TextStyle(color: Colors.white, fontSize: AppTypography.body)),
        ),
      ],
      body: ContentWidthLimit(
        child: id == null
            ? _form()
            : AsyncView<Notebook>(state: provider.detailOf(id), onRetry: _load, builder: (context, _) => _form()),
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotebookTypePicker(selected: _type, onSelected: (type) => setState(() => _type = type)),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (value) => (value ?? '').trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            NotebookTagEditor(controller: _tagController, tags: _tags, onAdd: _addTag, onRemove: _removeTag),
          ],
        ),
      ),
    );
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thẻ này đã tồn tại'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.warningStrong,
      ));
      return;
    }
    setState(() => _tags.add(trimmed));
    _tagController.clear();
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = NotebookDraft(
      title: _titleController.text.trim(),
      content: _contentController.text,
      type: _type,
      tags: List.of(_tags),
    );
    final error = await context.read<NotebookProvider>().save(draft, id: widget.noteId);
    if (!mounted) return;

    final saved = widget.noteId == null ? 'Tạo ghi chú thành công' : 'Cập nhật ghi chú thành công';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? saved),
      backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
    ));
    if (error == null) Navigator.pop(context);
  }
}
