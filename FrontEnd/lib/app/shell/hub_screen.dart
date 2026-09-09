import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/content_pane.dart';
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

            return GridView.builder(
              padding: padding,
              itemCount: destination.entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // Chiều cao cố định thay cho tỉ lệ: tỉ lệ làm thẻ cao vống lên
                // khi cột rộng ra, còn nội dung thẻ thì không đổi.
                mainAxisExtent: 92,
              ),
              itemBuilder: (context, i) =>
                  _HubTile(entry: destination.entries[i]),
            );
          },
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.entry});

  final AppNavEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(entry.path),
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(entry.icon, color: entry.color),
              ),
              AppGap.md,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.subtitle != null)
                      Text(
                        entry.subtitle!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
