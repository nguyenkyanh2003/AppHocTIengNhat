import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_form_parts.dart';

class CreateFlashcardDeckScreen extends StatefulWidget {
  const CreateFlashcardDeckScreen({super.key});

  /// Danh mục bộ thẻ và tên hiển thị.
  static const categories = {
    'vocabulary': 'Từ vựng',
    'kanji': 'Kanji',
    'grammar': 'Ngữ pháp',
    'custom': 'Tùy chỉnh',
    'other': 'Khác',
  };

  static const levels = ['N5', 'N4', 'N3', 'N2', 'N1', 'beginner', 'intermediate', 'advanced', 'other'];

  @override
  State<CreateFlashcardDeckScreen> createState() => _CreateFlashcardDeckScreenState();
}

class _CreateFlashcardDeckScreenState extends State<CreateFlashcardDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'custom';
  String? _selectedLevel;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createDeck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<FlashcardProvider>();
    final description = _descriptionController.text.trim();
    final result = await provider.createDeck(
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      isPublic: _isPublic,
      category: _selectedCategory,
      level: _selectedLevel,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result != null ? 'Tạo bộ thẻ thành công!' : provider.error ?? 'Có lỗi xảy ra'),
        backgroundColor: result != null ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
    if (result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);
    return AppScaffold(
      title: 'Tạo Bộ Thẻ Mới',
      body: ContentWidthLimit(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: flashcardInputDecoration(
                  label: 'Tiêu đề *',
                  hint: 'Ví dụ: Từ vựng N5 Chủ đề Gia đình',
                  icon: Icons.title,
                ),
                validator: requiredText('Vui lòng nhập tiêu đề'),
                maxLength: 100,
              ),
              gap,
              TextFormField(
                controller: _descriptionController,
                decoration: flashcardInputDecoration(
                  label: 'Mô tả (tùy chọn)',
                  hint: 'Mô tả ngắn về bộ thẻ này',
                  icon: Icons.description,
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              gap,
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: flashcardInputDecoration(label: 'Danh mục', icon: Icons.category),
                items: [
                  for (final MapEntry(key: value, value: name) in CreateFlashcardDeckScreen.categories.entries)
                    DropdownMenuItem(
                      value: value,
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              gap,
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                isExpanded: true,
                decoration: flashcardInputDecoration(label: 'Cấp độ (tùy chọn)', icon: Icons.bar_chart),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Không chọn', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  for (final level in CreateFlashcardDeckScreen.levels)
                    DropdownMenuItem(value: level, child: Text(level)),
                ],
                onChanged: (value) => setState(() => _selectedLevel = value),
              ),
              gap,
              Card(
                child: SwitchListTile(
                  title: const Text('Công khai'),
                  subtitle: const Text('Cho phép người khác xem và học bộ thẻ này'),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                  secondary: Icon(
                    _isPublic ? Icons.public : Icons.lock,
                    color: _isPublic ? AppColors.success : context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FlashcardInfoNote('Sau khi tạo bộ thẻ, bạn có thể thêm các thẻ flashcard vào bộ.'),
              const SizedBox(height: AppSpacing.xl),
              FlashcardSubmitButton(label: 'Tạo Bộ Thẻ', loading: _isLoading, onPressed: _createDeck),
            ],
          ),
        ),
      ),
    );
  }
}
