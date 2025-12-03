import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notebook_provider.dart';
import '../../config/theme.dart';

class NotebookFormScreen extends StatefulWidget {
  final String? noteId;

  const NotebookFormScreen({Key? key, this.noteId}) : super(key: key);

  @override
  State<NotebookFormScreen> createState() => _NotebookFormScreenState();
}

class _NotebookFormScreenState extends State<NotebookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  String _selectedType = 'general';
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<NotebookProvider>();
    await provider.loadNoteDetail(widget.noteId!);
    
    final note = provider.selectedNote;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedType = note.type;
      _tags.addAll(note.tags);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'Tạo ghi chú mới' : 'Chỉnh sửa ghi chú'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loại ghi chú
                    const Text(
                      'Loại ghi chú',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip('Chung', 'general'),
                        _buildTypeChip('Từ vựng', 'vocabulary'),
                        _buildTypeChip('Ngữ pháp', 'grammar'),
                        _buildTypeChip('Kanji', 'kanji'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tiêu đề
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nội dung
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập nội dung';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    const Text(
                      'Thẻ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập thẻ...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: _addTag,
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _addTag(_tagController.text),
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
      selectedColor: _getTypeColor(type),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
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

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) {
      return;
    }
    
    if (_tags.contains(trimmedTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thẻ này đã tồn tại'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _tags.add(trimmedTag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<NotebookProvider>();
    bool success;

    if (widget.noteId == null) {
      // Tạo mới
      success = await provider.createNote(
        title: _titleController.text,
        content: _contentController.text,
        type: _selectedType,
        tags: _tags,
      );
    } else {
      // Cập nhật
      success = await provider.updateNote(
        widget.noteId!,
        title: _titleController.text,
        content: _contentController.text,
        type: _selectedType,
        tags: _tags,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Reload danh sách ghi chú
      await provider.loadNotes(refresh: true);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.noteId == null
              ? 'Tạo ghi chú thành công'
              : 'Cập nhật ghi chú thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Trả về true để refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
