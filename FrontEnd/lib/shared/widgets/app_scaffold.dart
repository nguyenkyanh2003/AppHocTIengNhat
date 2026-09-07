import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Khung màn hình chuẩn: AppBar, khoảng lề, kéo để làm mới.
///
/// Dùng thay cho việc mỗi screen tự dựng `Scaffold` + `AppBar` + `Padding`
/// với giá trị riêng.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padded = true,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Có giá trị thì bọc body trong `RefreshIndicator`.
  final Future<void> Function()? onRefresh;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;

  /// Đặt `false` cho màn hình tự quản lề (danh sách tràn viền, bản đồ...).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    Widget content = padded
        ? Padding(padding: AppSpacing.page, child: body)
        : body;

    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, leading: leading),
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
