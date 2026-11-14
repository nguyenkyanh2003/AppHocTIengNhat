import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_form_parts.dart';
import '../widgets/flashcard_preview_card.dart';

class EditFlashcardCardScreen extends StatefulWidget {
  final String deckId;
  final FlashcardCard? card; // null = tạo mới, có giá trị = chỉnh sửa

  const EditFlashcardCardScreen({super.key, required this.deckId, this.card});

  @override
  State<EditFlashcardCardScreen> createState() => _EditFlashcardCardScreenState();
}

class _EditFlashcardCardScreenState extends State<EditFlashcardCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _frontController = TextEditingController(text: widget.card?.front);
  late final _backController = TextEditingController(text: widget.card?.back);
  late final _frontSubtextController = TextEditingController(text: widget.card?.frontSubtext);
  late final _backSubtextController = TextEditingController(text: widget.card?.backSubtext);

  bool _isLoading = false;

  bool get _isEditing => widget.card != null;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _frontSubtextController.dispose();
    _backSubtextController.dispose();
    super.dispose();
  }

  static String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<FlashcardProvider>();
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    final success = _isEditing
        ? await provider.updateCard(
            deckId: widget.deckId,
            cardId: widget.card!.id!,
            front: front,
            back: back,
            frontSubtext: _optional(_frontSubtextController),
            backSubtext: _optional(_backSubtextController),
          )
        : await provider.addCard(
            deckId: widget.deckId,
            front: front,
            back: back,
            frontSubtext: _optional(_frontSubtextController),
            backSubtext: _optional(_backSubtextController),
          );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final saved = _isEditing ? 'Cập nhật thẻ thành công!' : 'Thêm thẻ thành công!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? saved : provider.error ?? 'Có lỗi xảy ra'),
        backgroundColor: success ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const sideTitle = TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold);
    const gap = SizedBox(height: AppSpacing.sm);
    const section = SizedBox(height: AppSpacing.xl);

    return AppScaffold(
      title: _isEditing ? 'Sửa Thẻ' : 'Thêm Thẻ Mới',
      body: ContentWidthLimit(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              const FlashcardInfoNote(
                'Tạo thẻ flashcard giống Quizlet: Mặt trước thường là từ/câu hỏi, mặt sau là nghĩa/đáp án.',
              ),
              section,
              const Text('Mặt trước', style: sideTitle),
              gap,
              TextFormField(
                controller: _frontController,
                decoration: flashcardInputDecoration(
                  label: 'Nội dung chính *',
                  hint: 'Ví dụ: 学生 hoặc "Con mèo ăn cá"',
                  icon: Icons.credit_card,
                ),
                validator: requiredText('Vui lòng nhập nội dung mặt trước'),
                maxLength: 200,
              ),
              gap,
              TextFormField(
                controller: _frontSubtextController,
                decoration: flashcardInputDecoration(
                  label: 'Phụ đề (tùy chọn)',
                  hint: 'Ví dụ: がくせい, phiên âm, v.v.',
                  icon: Icons.subtitles,
                ),
                maxLength: 200,
              ),
              section,
              const Divider(thickness: 2),
              section,
              const Text('Mặt sau', style: sideTitle),
              gap,
              TextFormField(
                controller: _backController,
                decoration: flashcardInputDecoration(
                  label: 'Nội dung chính *',
                  hint: 'Ví dụ: Học sinh',
                  icon: Icons.credit_card_outlined,
                ),
                validator: requiredText('Vui lòng nhập nội dung mặt sau'),
                maxLength: 200,
              ),
              gap,
              TextFormField(
                controller: _backSubtextController,
                decoration: flashcardInputDecoration(
                  label: 'Phụ đề (tùy chọn)',
                  hint: 'Ví dụ: Người đang học tập',
                  icon: Icons.subtitles_outlined,
                ),
                maxLines: 2,
                maxLength: 300,
              ),
              section,
              FlashcardPreviewCard(
                frontController: _frontController,
                backController: _backController,
                frontSubtextController: _frontSubtextController,
                backSubtextController: _backSubtextController,
              ),
              section,
              FlashcardSubmitButton(
                label: _isEditing ? 'Lưu Thay Đổi' : 'Thêm Thẻ',
                loading: _isLoading,
                onPressed: _saveCard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
