import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/flashcard_deck.dart';
import '../providers/flashcard_provider.dart';

/// Bảng dưới để thêm một từ vựng vào bộ thẻ có sẵn hoặc một bộ mới.
class AddToFlashcardDialog extends StatefulWidget {
  const AddToFlashcardDialog({super.key, required this.card});

  final FlashcardCardDraft card;

  /// Trả `true` khi đã thêm.
  static Future<bool?> show(
    BuildContext context, {
    required String front,
    required String back,
    String? frontSubtext,
    String? backSubtext,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToFlashcardDialog(
        card: FlashcardCardDraft(front: front, back: back, frontSubtext: frontSubtext, backSubtext: backSubtext),
      ),
    );
  }

  @override
  State<AddToFlashcardDialog> createState() => _AddToFlashcardDialogState();
}

class _AddToFlashcardDialogState extends State<AddToFlashcardDialog> {
  final _newDeckTitle = TextEditingController();
  bool _creatingNew = false;
  String? _selectedDeckId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FlashcardProvider>().loadDecks();
    });
  }

  @override
  void dispose() {
    _newDeckTitle.dispose();
    super.dispose();
  }

  Future<void> _addTo(String deckId) =>
      _finish(context.read<FlashcardProvider>().addCard(deckId, widget.card), 'Đã thêm vào bộ flashcard!');

  Future<void> _addToNewDeck() async {
    final title = _newDeckTitle.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập tên bộ thẻ'),
        backgroundColor: AppColors.warningStrong,
      ));
      return;
    }
    await _finish(
      context.read<FlashcardProvider>().addCardToNewDeck(title, widget.card),
      'Đã tạo bộ "$title" và thêm thẻ!',
    );
  }

  /// Xong thì đóng bảng; lỗi thì giữ bảng mở để người dùng thử lại.
  Future<void> _finish(Future<String?> write, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await write;
    if (error == null) navigator.pop(true);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? done),
      backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: context.colors.border, borderRadius: AppRadius.pillAll),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Icon(Icons.style, color: context.colors.primary),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Thêm vào Flashcard',
                  style: TextStyle(fontSize: AppTypography.title, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CardPreview(card: widget.card),
          const Divider(height: AppSpacing.xl),
          Expanded(
            child: provider.isSaving
                ? const Center(child: CircularProgressIndicator())
                : _creatingNew
                    ? _NewDeckForm(controller: _newDeckTitle, onSubmit: _addToNewDeck)
                    : AsyncView<List<FlashcardDeck>>(
                        state: provider.decks,
                        onRetry: provider.loadDecks,
                        isEmpty: (decks) => decks.isEmpty,
                        emptyTitle: 'Chưa có bộ flashcard nào',
                        emptyIcon: Icons.folder_open,
                        emptyAction: TextButton(
                          onPressed: () => setState(() => _creatingNew = true),
                          child: const Text('Tạo bộ mới'),
                        ),
                        builder: (context, decks) => _DeckPicker(
                          decks: decks,
                          selectedId: _selectedDeckId,
                          onSelect: (id) => setState(() => _selectedDeckId = _selectedDeckId == id ? null : id),
                          onAdd: _addTo,
                        ),
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.page,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _creatingNew = !_creatingNew),
                      icon: Icon(_creatingNew ? Icons.list : Icons.add),
                      label: Text(_creatingNew ? 'Chọn bộ có sẵn' : 'Tạo bộ mới'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.card});

  final FlashcardCardDraft card;

  @override
  Widget build(BuildContext context) {
    final subtext = card.frontSubtext;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.front, style: const TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold)),
                if (subtext != null)
                  Text(subtext, style: TextStyle(fontSize: AppTypography.bodySmall, color: context.colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: context.colors.textDisabled),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(card.back, style: const TextStyle(fontSize: AppTypography.body), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Chạm một bộ để chọn, rồi bấm "Thêm" trên chính bộ đó.
class _DeckPicker extends StatelessWidget {
  const _DeckPicker({required this.decks, required this.selectedId, required this.onSelect, required this.onAdd});

  final List<FlashcardDeck> decks;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        for (final deck in decks)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            color: deck.id == selectedId ? AppColors.primary.withValues(alpha: 0.1) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(Icons.style, color: context.colors.primary),
              ),
              title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${deck.cardCount} thẻ'),
              trailing: deck.id == selectedId
                  ? FilledButton(onPressed: () => onAdd(deck.id), child: const Text('Thêm'))
                  : const Icon(Icons.chevron_right),
              onTap: () => onSelect(deck.id),
            ),
          ),
      ],
    );
  }
}

class _NewDeckForm extends StatelessWidget {
  const _NewDeckForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tạo bộ flashcard mới', style: TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Tên bộ flashcard *',
              hintText: 'Ví dụ: Từ vựng N5 yêu thích',
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              prefixIcon: Icon(Icons.title),
            ),
            autofocus: true,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.check), label: const Text('Tạo và thêm thẻ')),
          ),
        ],
      ),
    );
  }
}
