import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_theme.dart';

class EditFlashcardCardScreen extends StatefulWidget {
  final String deckId;
  final FlashcardCard? card; // null = tạo mới, có giá trị = chỉnh sửa

  const EditFlashcardCardScreen({
    Key? key,
    required this.deckId,
    this.card,
  }) : super(key: key);

  @override
  State<EditFlashcardCardScreen> createState() =>
      _EditFlashcardCardScreenState();
}

class _EditFlashcardCardScreenState extends State<EditFlashcardCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _frontSubtextController = TextEditingController();
  final _backSubtextController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _frontController.text = widget.card!.front;
      _backController.text = widget.card!.back;
      _frontSubtextController.text = widget.card!.frontSubtext ?? '';
      _backSubtextController.text = widget.card!.backSubtext ?? '';
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _frontSubtextController.dispose();
    _backSubtextController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<FlashcardProvider>();
    bool success;

    if (widget.card == null) {
      // Tạo mới
      success = await provider.addCard(
        deckId: widget.deckId,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        frontSubtext: _frontSubtextController.text.trim().isEmpty
            ? null
            : _frontSubtextController.text.trim(),
        backSubtext: _backSubtextController.text.trim().isEmpty
            ? null
            : _backSubtextController.text.trim(),
      );
    } else {
      // Cập nhật
      success = await provider.updateCard(
        deckId: widget.deckId,
        cardId: widget.card!.id!,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        frontSubtext: _frontSubtextController.text.trim().isEmpty
            ? null
            : _frontSubtextController.text.trim(),
        backSubtext: _backSubtextController.text.trim().isEmpty
            ? null
            : _backSubtextController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.card == null
              ? 'Thêm thẻ thành công!'
              : 'Cập nhật thẻ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Thẻ' : 'Thêm Thẻ Mới'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tạo thẻ flashcard giống Quizlet: Mặt trước thường là từ/câu hỏi, mặt sau là nghĩa/đáp án.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Front (Mặt trước)
            const Text(
              'Mặt trước',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frontController,
              decoration: InputDecoration(
                labelText: 'Nội dung chính *',
                hintText: 'Ví dụ: 学生 hoặc "Con mèo ăn cá"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập nội dung mặt trước';
                }
                return null;
              },
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frontSubtextController,
              decoration: InputDecoration(
                labelText: 'Phụ đề (tùy chọn)',
                hintText: 'Ví dụ: がくせい, phiên âm, v.v.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.subtitles),
              ),
              maxLength: 200,
            ),
            const SizedBox(height: 24),

            // Divider
            const Divider(thickness: 2),
            const SizedBox(height: 24),

            // Back (Mặt sau)
            const Text(
              'Mặt sau',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                labelText: 'Nội dung chính *',
                hintText: 'Ví dụ: Học sinh',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.credit_card_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập nội dung mặt sau';
                }
                return null;
              },
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backSubtextController,
              decoration: InputDecoration(
                labelText: 'Phụ đề (tùy chọn)',
                hintText: 'Ví dụ: Người đang học tập',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.subtitles_outlined),
              ),
              maxLines: 2,
              maxLength: 300,
            ),
            const SizedBox(height: 24),

            // Preview card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xem trước:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mặt trước:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _frontController.text.isEmpty
                          ? '(Trống)'
                          : _frontController.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_frontSubtextController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _frontSubtextController.text,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    const Divider(height: 24),
                    const Text(
                      'Mặt sau:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _backController.text.isEmpty
                          ? '(Trống)'
                          : _backController.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_backSubtextController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _backSubtextController.text,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Lưu Thay Đổi' : 'Thêm Thẻ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
