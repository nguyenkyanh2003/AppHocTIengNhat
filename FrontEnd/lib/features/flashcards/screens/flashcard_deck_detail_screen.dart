import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard_deck.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

class FlashcardDeckDetailScreen extends StatefulWidget {
  final String deckId;

  const FlashcardDeckDetailScreen({
    Key? key,
    required this.deckId,
  }) : super(key: key);

  @override
  State<FlashcardDeckDetailScreen> createState() =>
      _FlashcardDeckDetailScreenState();
}

class _FlashcardDeckDetailScreenState extends State<FlashcardDeckDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadDeckById(widget.deckId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chi Tiết Bộ Thẻ',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditDeckDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteDeckDialog(),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<FlashcardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.selectedDeck == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.selectedDeck == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.textDisabled),
                    const SizedBox(height: 16),
                    const Text(
                      'Lỗi tải dữ liệu',
                      style: TextStyle(fontSize: AppTypography.subtitle, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.loadDeckById(widget.deckId),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final deck = provider.selectedDeck;
            if (deck == null) {
              return const Center(child: Text('Không tìm thấy bộ thẻ'));
            }

            return Column(
              children: [
                _buildDeckHeader(deck),
                Expanded(child: _buildCardsList(deck)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Thẻ'),
        backgroundColor: AppTheme.primaryColor,
      ),
      backgroundColor: AppColors.surfaceVariant,
    );
  }

  Widget _buildDeckHeader(FlashcardDeck deck) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deck.title,
            style: const TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (deck.description != null && deck.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              deck.description!,
              style: const TextStyle(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                  Icons.style, '${deck.totalCards} thẻ', AppColors.primary),
              const SizedBox(width: 8),
              _buildStatChip(Icons.play_circle_outline,
                  '${deck.studyCount} lượt', AppColors.warning),
              if (deck.level != null) ...[
                const SizedBox(width: 8),
                _buildStatChip(Icons.bar_chart, deck.level!, Colors.purple),
              ],
            ],
          ),
          if (deck.totalCards > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startStudy(deck),
                icon: const Icon(Icons.school),
                label: const Text('Bắt đầu học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardsList(FlashcardDeck deck) {
    if (deck.cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 80, color: AppColors.border),
            SizedBox(height: 16),
            Text(
              'Chưa có thẻ nào',
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Thêm thẻ đầu tiên của bạn!',
              style: TextStyle(fontSize: AppTypography.bodySmall, color: AppColors.textDisabled),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deck.cards.length,
      itemBuilder: (context, index) {
        final card = deck.cards[index];
        return _buildCardItem(card, index);
      },
    );
  }

  Widget _buildCardItem(card, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditCardDialog(card),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.front,
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.frontSubtext != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.frontSubtext!,
                          style: const TextStyle(
                            fontSize: AppTypography.caption,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        card.back,
                        style: const TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCardDialog(card);
                    } else if (value == 'delete') {
                      _showDeleteCardDialog(card);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startStudy(FlashcardDeck deck) {
    // Ghi nhận lượt học
    context.read<FlashcardProvider>().recordStudy(deck.id);

    // `extra` mang theo bộ thẻ; mở thẳng URL này thì route tự đưa về
    // trang bộ thẻ vì không có gì để khôi phục.
    context.push('/flashcards/${deck.id}/study', extra: deck);
  }

  void _showAddCardDialog() {
    context
        .push(
      '/flashcards/${widget.deckId}/cards/new',
    )
        .then((_) {
      if (!mounted) return;
      context.read<FlashcardProvider>().loadDeckById(widget.deckId);
    });
  }

  void _showEditCardDialog(FlashcardCard card) {
    context
        .push('/flashcards/${widget.deckId}/cards/${card.id}/edit', extra: card)
        .then((_) {
      if (!mounted) return;
      context.read<FlashcardProvider>().loadDeckById(widget.deckId);
    });
  }

  void _showDeleteCardDialog(card) {
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
              final provider = this.context.read<FlashcardProvider>();
              Navigator.pop(context);
              final success = await provider.deleteCard(
                deckId: widget.deckId,
                cardId: card.id!,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa thẻ thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showEditDeckDialog() {
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
              final provider = this.context.read<FlashcardProvider>();
              Navigator.pop(context);
              final success = await provider.updateDeck(
                deckId: widget.deckId,
                title: titleController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );

              if (success && mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật thành công'),
                    backgroundColor: AppColors.success,
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

  void _showDeleteDeckDialog() {
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
              final provider = this.context.read<FlashcardProvider>();
              final navigator = Navigator.of(this.context);
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              final success = await provider.deleteDeck(widget.deckId);

              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Xóa bộ thẻ thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
                navigator.pop(); // Pop back to list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
