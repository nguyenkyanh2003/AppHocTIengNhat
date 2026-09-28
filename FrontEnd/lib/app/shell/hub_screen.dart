import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/content_pane.dart';
import '../../shared/widgets/hub_tile.dart';
import '../theme/app_tokens.dart';
import 'app_navigation.dart';

/// Trang hub của một đích đến: liệt kê các mục con của nhóm.
///
/// Một màn hình duy nhất phục vụ mọi nhóm (`/study`, `/review`, `/account`,
/// `/admin`) vì chúng chỉ khác nhau ở dữ liệu, không khác nhau ở bố cục.
///
/// Số cột tính từ **bề rộng vùng nội dung** (`LayoutBuilder`), không từ bề
/// rộng cửa sổ — ở đây rail đã chiếm chỗ rồi.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.destinationPath});

  final String destinationPath;

  @override
  Widget build(BuildContext context) {
    final destination = AppNavigation.destinations(context)
        .firstWhere((d) => d.path == destinationPath);
    final footer = destination.footer;

    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = ContentPane.paddingFor(
              constraints.maxWidth,
              maxWidth: AppContentWidth.dashboard,
            );
            final usable = constraints.maxWidth - padding.horizontal;
            final columns = usable ~/ 280 < 1 ? 1 : usable ~/ 280;
            final grid = SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              // Chiều cao cố định thay cho tỉ lệ: tỉ lệ làm ô cao vống lên
              // khi cột rộng ra, còn nội dung ô thì không đổi.
              mainAxisExtent: _tileExtent(context),
            );

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: footer == null
                      ? padding
                      : padding.copyWith(bottom: 0),
                  sliver: SliverGrid(
                    gridDelegate: grid,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _EntryTile(entry: destination.entries[i]),
                      childCount: destination.entries.length,
                    ),
                  ),
                ),
                // Ô hành động (Đăng xuất) tách khỏi các mục điều hướng bằng một
                // khoảng lớn, nhưng vẫn đúng kích thước một ô của lưới.
                if (footer != null)
                  SliverPadding(
                    padding: padding.copyWith(top: AppSpacing.xl),
                    sliver: SliverGrid(
                      gridDelegate: grid,
                      delegate: SliverChildListDelegate([footer(context)]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Chiều cao một ô hub.
///
/// Ô gồm hai phần: khung (biểu tượng 44px + lề) **không** giãn, và phần chữ
/// (một dòng tiêu đề + tối đa hai dòng mô tả) **có** giãn theo cỡ chữ hệ
/// thống. Cố định cả ô ở 92px làm nội dung tràn ngay khi người dùng phóng cỡ
/// chữ lên, nên chỉ phần chữ được nhân theo `textScaler`.
double _tileExtent(BuildContext context) {
  const iconBox = 44.0;
  const textBlock = 54.0; // 1 dòng titleMedium + 2 dòng bodySmall
  final scaled = MediaQuery.textScalerOf(context).scale(textBlock);
  final content = scaled > iconBox ? scaled : iconBox;
  return content + AppSpacing.card.vertical + AppSpacing.sm;
}

/// Ô dẫn tới trang của một mục con.
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final AppNavEntry entry;

  @override
  Widget build(BuildContext context) {
    return HubTile(
      label: entry.label,
      subtitle: entry.subtitle,
      icon: entry.icon,
      color: entry.color,
      onTap: () => context.go(entry.path),
      trailing: entry.trailing?.call(context),
    );
  }
}
