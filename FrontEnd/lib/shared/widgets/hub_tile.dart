import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Một ô trên trang hub: biểu tượng trong khung màu, tiêu đề và mô tả ngắn.
///
/// Dùng chung cho mục điều hướng lẫn ô hành động (Đăng xuất), để hai loại ô
/// luôn cùng kích thước và cùng cách co chữ.
class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.trailing,
  });

  final String label;
  final String? subtitle;
  final IconData icon;

  /// Màu của biểu tượng và nền nhạt quanh nó.
  final Color color;

  /// Màu tiêu đề; để trống thì theo theme. Ô hành động nguy hiểm dùng màu lỗi.
  final Color? labelColor;

  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: color),
              ),
              AppGap.md,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // `Flexible` để khi người dùng phóng to cỡ chữ hệ thống,
                    // khối chữ bớt dòng thay vì đội cao hơn ô thẻ và tràn.
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: labelColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null)
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                AppGap.sm,
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
