import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/vocabulary.dart';
import 'vocabulary_card.dart';

/// Danh sách từ vựng: xử lý bốn trạng thái qua [AsyncView] và tải thêm khi cuộn
/// tới cuối.
class VocabularyListView extends StatelessWidget {
  const VocabularyListView({
    super.key,
    required this.state,
    required this.hasNextPage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpen,
    this.onAddToFlashcard,
    this.onPlayAudio,
  });

  final ViewState<List<Vocabulary>> state;
  final bool hasNextPage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final void Function(Vocabulary vocabulary) onOpen;
  final void Function(Vocabulary vocabulary)? onAddToFlashcard;
  final void Function(Vocabulary vocabulary)? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Vocabulary>>(
      state: state,
      onRetry: onRefresh,
      isEmpty: (items) => items.isEmpty,
      emptyTitle: 'Không tìm thấy từ vựng',
      emptyMessage: 'Thử đổi từ khoá hoặc bỏ bớt bộ lọc cấp độ.',
      emptyIcon: Icons.search_off,
      builder: (context, items) => RefreshIndicator(
        onRefresh: onRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200 &&
                hasNextPage) {
              onLoadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            itemCount: items.length + (hasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final vocabulary = items[index];
              return VocabularyCard(
                vocabulary: vocabulary,
                onTap: () => onOpen(vocabulary),
                onAddToFlashcard: onAddToFlashcard == null
                    ? null
                    : () => onAddToFlashcard!(vocabulary),
                onPlayAudio:
                    onPlayAudio == null ? null : () => onPlayAudio!(vocabulary),
              );
            },
          ),
        ),
      ),
    );
  }
}
