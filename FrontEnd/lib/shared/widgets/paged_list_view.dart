import 'package:flutter/material.dart';

import 'load_more_footer.dart';

/// Danh sách phân trang: cuộn gần cuối thì gọi [onLoadMore], ô cuối hiện vòng
/// xoay hoặc lỗi tải thêm kèm nút thử lại. Danh sách đang có không bao giờ bị
/// thay bằng trạng thái tải, nên vị trí cuộn của người dùng được giữ nguyên.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onLoadMore,
    this.padding,
    this.loadMoreExtent = 300,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final VoidCallback onLoadMore;
  final EdgeInsetsGeometry? padding;

  /// Còn ít hơn chừng này điểm ảnh tới cuối thì tải trang sau.
  final double loadMoreExtent;

  @override
  Widget build(BuildContext context) {
    final showFooter = hasMore || isLoadingMore || loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore && notification is ScrollEndNotification && notification.metrics.extentAfter < loadMoreExtent) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: padding,
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) => index == items.length
            ? LoadMoreFooter(error: loadMoreError, onRetry: onLoadMore)
            : itemBuilder(context, items[index]),
      ),
    );
  }
}
