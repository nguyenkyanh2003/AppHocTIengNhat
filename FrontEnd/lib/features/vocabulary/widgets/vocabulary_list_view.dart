import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/vocabulary.dart';
import 'vocabulary_card.dart';

/// Danh sách từ vựng: xử lý bốn trạng thái qua [AsyncView] và tải thêm khi cuộn
/// tới cuối.
///
/// Việc tải thêm chỉ hiển thị ở cuối danh sách. Danh sách đang có không bị thay
/// bằng trạng thái loading, nhờ vậy `ListView` không bị tháo và vị trí cuộn của
/// người dùng được giữ nguyên.
class VocabularyListView extends StatelessWidget {
  const VocabularyListView({
    super.key,
    required this.state,
    required this.hasNextPage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpen,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.onAddToFlashcard,
    this.onPlayAudio,
  });

  final ViewState<List<Vocabulary>> state;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String? loadMoreError;
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
        // Lề tính theo bề rộng còn lại, bơm thẳng vào danh sách: giữ được ảo
        // hoá và giữ thanh cuộn ở mép ngoài.
        child: ContentPaneList(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          builder: (context, padding) => PagedListView<Vocabulary>(
            items: items,
            padding: padding,
            hasMore: hasNextPage,
            isLoadingMore: isLoadingMore,
            loadMoreError: loadMoreError,
            onLoadMore: onLoadMore,
            loadMoreExtent: 200,
            itemBuilder: (context, vocabulary) => VocabularyCard(
              vocabulary: vocabulary,
              onTap: () => onOpen(vocabulary),
              onAddToFlashcard: onAddToFlashcard == null ? null : () => onAddToFlashcard!(vocabulary),
              onPlayAudio: onPlayAudio == null ? null : () => onPlayAudio!(vocabulary),
            ),
          ),
        ),
      ),
    );
  }
}
