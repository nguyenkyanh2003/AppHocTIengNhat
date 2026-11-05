import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_tokens.dart';

/// Xác nhận rồi xoá một thẻ.
void showDeleteFlashcardDialog(BuildContext context, FlashcardCard card,
    {required String deckId}) {
  final hostContext = context;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xóa thẻ'),
      content: const Text('Bạn có chắc chắn muốn xóa thẻ này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = hostContext.read<FlashcardProvider>();
            Navigator.pop(context);
            final success = await provider.deleteCard(
              deckId: deckId,
              cardId: card.id!,
            );

            if (success && hostContext.mounted) {
              ScaffoldMessenger.of(hostContext).showSnackBar(
                const SnackBar(
                  content: Text('Xóa thẻ thành công'),
                  backgroundColor: AppColors.successStrong,
                ),
              );
            }
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}

/// Hộp thoại sửa thông tin bộ thẻ.
void showEditFlashcardDeckDialog(BuildContext context,
    {required String deckId}) {
  final hostContext = context;
  final deck = context.read<FlashcardProvider>().selectedDeck;
  if (deck == null) return;

  final titleController = TextEditingController(text: deck.title);
  final descController = TextEditingController(text: deck.description ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sửa bộ thẻ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = hostContext.read<FlashcardProvider>();
            Navigator.pop(context);
            final success = await provider.updateDeck(
              deckId: deckId,
              title: titleController.text.trim(),
              description: descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim(),
            );

            if (success && hostContext.mounted) {
              ScaffoldMessenger.of(hostContext).showSnackBar(
                const SnackBar(
                  content: Text('Cập nhật thành công'),
                  backgroundColor: AppColors.successStrong,
                ),
              );
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}

/// Xác nhận rồi xoá cả bộ thẻ.
void showDeleteFlashcardDeckDialog(BuildContext context,
    {required String deckId}) {
  final hostContext = context;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xóa bộ thẻ'),
      content: const Text(
          'Bạn có chắc chắn muốn xóa bộ thẻ này? Hành động này không thể hoàn tác.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = hostContext.read<FlashcardProvider>();
            final navigator = Navigator.of(hostContext);
            final messenger = ScaffoldMessenger.of(hostContext);
            Navigator.pop(context);
            final success = await provider.deleteDeck(deckId);

            if (success && hostContext.mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Xóa bộ thẻ thành công'),
                  backgroundColor: AppColors.successStrong,
                ),
              );
              navigator.pop(); // Pop back to list
            }
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
