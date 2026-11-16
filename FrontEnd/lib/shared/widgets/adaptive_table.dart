import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'load_more_footer.dart';

/// Một cột của [AdaptiveTable].
@immutable
class AdaptiveColumn<T> {
  const AdaptiveColumn({
    required this.label,
    required this.cell,
    this.width,
    this.minWidth = 140,
    this.alignEnd = false,
  });

  final String label;

  /// Ô dữ liệu của một dòng.
  final Widget Function(BuildContext context, T item) cell;

  /// Bề rộng cố định. Để `null` thì cột co giãn theo chỗ còn thừa.
  final double? width;

  /// Bề rộng tối thiểu khi cột co giãn. Tổng các giá trị này quyết định khi
  /// nào bảng đủ chỗ để hiện — xem [AdaptiveTable].
  final double minWidth;

  final bool alignEnd;

  double get _floor => width ?? minWidth;
}

/// Trạng thái tải thêm của một [AdaptiveTable] phân trang (thường lấy thẳng từ
/// `PagedList` của provider).
@immutable
class TablePaging {
  const TablePaging({
    required this.hasMore,
    required this.isLoadingMore,
    required this.error,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;

  /// Lỗi của lần tải thêm gần nhất; hiện ở ô cuối kèm nút thử lại.
  final String? error;
  final VoidCallback onLoadMore;

  bool get _showFooter => hasMore || isLoadingMore || error != null;
}

/// Danh sách bản ghi: **thẻ** trên vùng hẹp, **bảng** trên vùng rộng.
///
/// Ngưỡng chuyển không phải một con số chọn bừa: bảng chỉ hiện khi vùng nội
/// dung rộng ít nhất bằng tổng bề rộng tối thiểu của các cột. Khai báo thêm
/// cột thì ngưỡng tự dâng lên, nên không có cách nào dựng ra một cái bảng bị
/// bóp nát.
///
/// Bề rộng đo bằng [LayoutBuilder] — đây là chỗ trống thật sau khi thanh điều
/// hướng đã chiếm phần của nó, không phải bề rộng cửa sổ.
///
/// Khi vùng nội dung hẹp hơn tổng tối thiểu nhưng vẫn muốn xem dạng bảng,
/// người dùng cuộn ngang: header và các dòng nằm trong **cùng một** vùng cuộn
/// ngang nên không bao giờ lệch cột.
class AdaptiveTable<T> extends StatefulWidget {
  const AdaptiveTable({
    super.key,
    required this.items,
    required this.columns,
    required this.cardBuilder,
    this.onRowTap,
    this.rowKey,
    this.padding = EdgeInsets.zero,
    this.onRefresh,
    this.paging,
  });

  final List<T> items;
  final List<AdaptiveColumn<T>> columns;

  /// Bố cục dòng trên vùng hẹp. Giữ nguyên thẻ mà màn hình vốn đã có.
  final Widget Function(BuildContext context, T item) cardBuilder;

  final void Function(T item)? onRowTap;

  /// Khoá ổn định cho mỗi dòng, giúp Flutter giữ đúng trạng thái khi danh sách
  /// thay đổi thứ tự.
  final Key Function(T item)? rowKey;

  final EdgeInsets padding;

  /// Kéo-để-làm-mới, gắn vào **đúng** danh sách dọc của từng chế độ.
  ///
  /// Không để nơi gọi tự bọc `RefreshIndicator` bên ngoài: ở chế độ bảng,
  /// vùng cuộn gần nhất là vùng cuộn **ngang**, nên cử chỉ sẽ rơi vào sai chỗ.
  /// Đây vẫn là lối phụ cho cảm ứng — nút làm mới trên `AppBar` mới là lối
  /// chính, và là lối duy nhất có trên desktop.
  final Future<void> Function()? onRefresh;

  /// Có thì cuộn gần cuối là tải trang sau, ô cuối hiện vòng xoay hoặc lỗi —
  /// như `PagedListView`, ở cả hai chế độ.
  final TablePaging? paging;

  /// Còn ít hơn chừng này điểm ảnh tới cuối thì tải trang sau.
  static const _loadMoreExtent = 300.0;

  @override
  State<AdaptiveTable<T>> createState() => _AdaptiveTableState<T>();
}

class _AdaptiveTableState<T> extends State<AdaptiveTable<T>> {
  // Thanh cuộn ngang không tự hiện trên web nếu không có controller tường
  // minh; danh sách quản trị gần như luôn cần cuộn ngang trên laptop nhỏ.
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  double get _minTableWidth =>
      widget.columns.fold<double>(0, (sum, c) => sum + c._floor) +
      AppSpacing.lg * 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - widget.padding.horizontal;
        if (available < _minTableWidth) {
          return _list(
            padding: widget.padding,
            itemBuilder: (context, i) => widget.cardBuilder(context, widget.items[i]),
          );
        }
        return Padding(
          padding: widget.padding,
          child: _table(context, available),
        );
      },
    );
  }

  /// Danh sách dọc của cả hai chế độ: kéo để làm mới và tải thêm gắn ở đây.
  Widget _list({EdgeInsets? padding, required IndexedWidgetBuilder itemBuilder}) {
    final paging = widget.paging;
    final footer = paging != null && paging._showFooter;
    Widget list = ListView.builder(
      padding: padding,
      itemCount: widget.items.length + (footer ? 1 : 0),
      itemBuilder: (context, i) => i == widget.items.length
          ? LoadMoreFooter(error: paging!.error, onRetry: paging.onLoadMore)
          : itemBuilder(context, i),
    );
    if (paging != null) {
      list = NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (paging.hasMore &&
              metrics.axis == Axis.vertical &&
              metrics.extentAfter < AdaptiveTable._loadMoreExtent) {
            paging.onLoadMore();
          }
          return false;
        },
        child: list,
      );
    }
    final onRefresh = widget.onRefresh;
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh, child: list);
  }

  Widget _table(BuildContext context, double available) {
    final tableWidth = available < _minTableWidth ? _minTableWidth : available;

    return Scrollbar(
      controller: _horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _HeaderRow<T>(columns: widget.columns),
              const Divider(height: 1),
              Expanded(
                child: _list(
                  itemBuilder: (context, i) {
                    final item = widget.items[i];
                    return _BodyRow<T>(
                      key: widget.rowKey?.call(item),
                      item: item,
                      columns: widget.columns,
                      striped: i.isOdd,
                      onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _cells<T>(
  BuildContext context,
  List<AdaptiveColumn<T>> columns,
  Widget Function(AdaptiveColumn<T> column) build,
) {
  return [
    for (final column in columns)
      if (column.width != null)
        SizedBox(width: column.width, child: build(column))
      else
        Expanded(child: build(column)),
  ];
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<AdaptiveColumn<T>> columns;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: _cells<T>(
          context,
          columns,
          (column) => Align(
            alignment:
                column.alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(column.label, style: style),
          ),
        ),
      ),
    );
  }
}

class _BodyRow<T> extends StatelessWidget {
  const _BodyRow({
    super.key,
    required this.item,
    required this.columns,
    required this.striped,
    this.onTap,
  });

  final T item;
  final List<AdaptiveColumn<T>> columns;
  final bool striped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: _cells<T>(
          context,
          columns,
          (column) => Align(
            alignment:
                column.alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: column.cell(context, item),
          ),
        ),
      ),
    );

    return Material(
      color: striped
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : Colors.transparent,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}
