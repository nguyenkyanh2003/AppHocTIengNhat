import 'package:flutter/material.dart';

/// Khung trang chuẩn: `AppBar`, thao tác, tab, `SafeArea` và nút nổi.
///
/// ## Ranh giới trách nhiệm
///
/// `AppScaffold` sở hữu **khung trang**. Nó cố ý **không** sở hữu:
///
/// - **Vùng cuộn.** Mỗi vùng nội dung tự quyết cách cuộn của mình. Một wrapper
///   cuộn dùng chung sẽ làm vỡ `TabBarView`, `PageView` và mọi `Expanded`
///   chứa danh sách — chúng cần chiều cao có giới hạn.
/// - **Bề rộng nội dung.** Việc đó của `ContentPane`.
/// - **Thanh điều hướng chính.** Việc đó của `AppShell`.
///
/// ## Làm mới dữ liệu
///
/// [onRefresh] dựng một **nút** trên `AppBar` — dùng được bằng chuột và bàn
/// phím, nên là đường làm mới duy nhất có trên desktop. Nếu màn hình còn muốn
/// kéo-để-làm-mới trên mobile thì tự gắn `RefreshIndicator` vào **đúng danh
/// sách** cần làm mới, không bọc cả trang.
///
/// ## SafeArea
///
/// Inset được áp **một lần duy nhất** ở đây. `AppShell` không bọc `SafeArea`
/// quanh trang, và screen cũng không tự bọc thêm.
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onRefresh,
    this.refreshTooltip = 'Làm mới',
    this.bottom,
    this.floatingActionButton,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Có giá trị thì thêm nút làm mới vào cuối [actions].
  final Future<void> Function()? onRefresh;
  final String refreshTooltip;

  /// `TabBar` hoặc thanh phụ nằm dưới tiêu đề.
  final PreferredSizeWidget? bottom;

  final Widget? floatingActionButton;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      ...?widget.actions,
      if (widget.onRefresh != null)
        IconButton(
          onPressed: _refreshing ? null : _refresh,
          tooltip: widget.refreshTooltip,
          icon: const Icon(Icons.refresh),
        ),
    ];

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.leading,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        actions: actions.isEmpty ? null : actions,
        bottom: widget.bottom,
      ),
      // `top: false` vì `AppBar` đã tiêu thụ inset trên; để `bottom` mặc định
      // để trang vẫn tránh gesture bar khi `AppShell` không dựng thanh dưới.
      body: SafeArea(top: false, child: widget.body),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
