import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Lưới có số cột theo chỗ trống thật của vùng nội dung, không theo bề rộng cửa sổ
/// (cửa sổ chưa trừ thanh điều hướng).
///
/// Chiều cao ô theo nội dung. `GridView` với `childAspectRatio` cố định làm chữ tràn
/// khi ô hẹp hoặc cỡ chữ lớn, nên lưới thống kê dùng widget này.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 160,
    this.maxColumns = 4,
    this.spacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / minTileWidth).floor().clamp(1, maxColumns);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
