import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';

/// Báo kết quả một thao tác ghi: [error] `null` là xong.
void _report(ScaffoldMessengerState messenger, String? error, String done) {
  messenger.showSnackBar(SnackBar(
    content: Text(error ?? done),
    backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
  ));
}

/// Hộp xác nhận chung: trả `true` khi người dùng bấm nút [confirmLabel].
Future<bool> _confirm(BuildContext context, {required String title, required String message}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
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
  return confirmed ?? false;
}

/// Xác nhận rồi xoá một thẻ.
Future<void> showDeleteFlashcardDialog(BuildContext context, FlashcardCard card, {required String deckId}) async {
  final provider = context.read<FlashcardProvider>();
  final messenger = ScaffoldMessenger.of(context);
  if (!await _confirm(context, title: 'Xóa thẻ', message: 'Bạn có chắc chắn muốn xóa thẻ này?')) return;

  _report(messenger, await provider.deleteCard(deckId, card.id), 'Xóa thẻ thành công');
}

/// Xác nhận rồi xoá cả bộ thẻ; xoá xong thì quay về danh sách.
Future<void> showDeleteFlashcardDeckDialog(BuildContext context, {required String deckId}) async {
  final provider = context.read<FlashcardProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final confirmed = await _confirm(
    context,
    title: 'Xóa bộ thẻ',
    message: 'Bạn có chắc chắn muốn xóa bộ thẻ này? Hành động này không thể hoàn tác.',
  );
  if (!confirmed) return;

  final error = await provider.deleteDeck(deckId);
  _report(messenger, error, 'Xóa bộ thẻ thành công');
  if (error == null) navigator.pop();
}

/// Hộp thoại sửa tên và mô tả của bộ thẻ.
Future<void> showEditFlashcardDeckDialog(BuildContext context, FlashcardDeck deck) async {
  final provider = context.read<FlashcardProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final title = TextEditingController(text: deck.title);
  final description = TextEditingController(text: deck.description ?? '');

  final save = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sửa bộ thẻ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: title,
              decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Lưu')),
      ],
    ),
  );
  final newTitle = title.text.trim();
  final newDescription = description.text.trim();
  title.dispose();
  description.dispose();
  if (save != true) return;
  if (newTitle.isEmpty) {
    _report(messenger, 'Tiêu đề bộ thẻ không được để trống.', '');
    return;
  }

  final error = await provider.updateDeck(deck.id, title: newTitle, description: newDescription);
  _report(messenger, error, 'Cập nhật thành công');
}
