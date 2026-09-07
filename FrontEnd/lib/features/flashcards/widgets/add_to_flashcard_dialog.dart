import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../../../app/theme/app_theme.dart';

/// Widget dialog để thêm từ vựng vào bộ flashcard
class AddToFlashcardDialog extends StatefulWidget {
  final String front; // Từ/Kanji
  final String back; // Nghĩa
  final String? frontSubtext; // Hiragana
  final String? backSubtext; // Ví dụ

  const AddToFlashcardDialog({
    Key? key,
    required this.front,
    required this.back,
    this.frontSubtext,
    this.backSubtext,
  }) : super(key: key);

  @override
  State<AddToFlashcardDialog> createState() => _AddToFlashcardDialogState();

  /// Helper method để hiển thị dialog
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
        front: front,
        back: back,
        frontSubtext: frontSubtext,
        backSubtext: backSubtext,
      ),
    );
  }
}

class _AddToFlashcardDialogState extends State<AddToFlashcardDialog> {
  bool _isLoading = false;
  bool _isCreatingNew = false;
  final _newDeckTitleController = TextEditingController();
  String? _selectedDeckId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadDecks(refresh: true);
    });
  }

  @override
  void dispose() {
    _newDeckTitleController.dispose();
    super.dispose();
  }

  Future<void> _addToExistingDeck(String deckId) async {
    setState(() => _isLoading = true);

    final provider = context.read<FlashcardProvider>();
    final success = await provider.addCard(
      deckId: deckId,
      front: widget.front,
      back: widget.back,
      frontSubtext: widget.frontSubtext,
      backSubtext: widget.backSubtext,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm vào bộ flashcard!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createNewDeckAndAdd() async {
    final title = _newDeckTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên bộ thẻ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<FlashcardProvider>();

    // Tạo bộ thẻ mới
    final newDeck = await provider.createDeck(
      title: title,
      category: 'vocabulary',
    );

    if (newDeck != null) {
      // Thêm thẻ vào bộ mới
      final success = await provider.addCard(
        deckId: newDeck.id,
        front: widget.front,
        back: widget.back,
        frontSubtext: widget.frontSubtext,
        backSubtext: widget.backSubtext,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo bộ "$title" và thêm thẻ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.style, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Thêm vào Flashcard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Preview card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.front,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.frontSubtext != null)
                        Text(
                          widget.frontSubtext!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.back,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Options
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isCreatingNew
                    ? _buildCreateNewSection()
                    : _buildDecksList(),
          ),

          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isCreatingNew = !_isCreatingNew);
                      },
                      icon: Icon(_isCreatingNew ? Icons.list : Icons.add),
                      label: Text(
                          _isCreatingNew ? 'Chọn bộ có sẵn' : 'Tạo bộ mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildDecksList() {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final myDecks = provider.decks;

        if (myDecks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Chưa có bộ flashcard nào',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _isCreatingNew = true);
                  },
                  child: const Text('Tạo bộ mới'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: myDecks.length,
          itemBuilder: (context, index) {
            final deck = myDecks[index];
            final isSelected = _selectedDeckId == deck.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.style,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  deck.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${deck.totalCards} thẻ'),
                trailing: isSelected
                    ? ElevatedButton(
                        onPressed: () => _addToExistingDeck(deck.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thêm'),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedDeckId = isSelected ? null : deck.id;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateNewSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tạo bộ flashcard mới',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newDeckTitleController,
            decoration: InputDecoration(
              labelText: 'Tên bộ flashcard *',
              hintText: 'Ví dụ: Từ vựng N5 yêu thích',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createNewDeckAndAdd,
              icon: const Icon(Icons.check),
              label: const Text('Tạo và thêm thẻ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
