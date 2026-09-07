import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Thẻ nội dung dùng chung: bo góc, lề và hiệu ứng chạm thống nhất.
///
/// Có thể gắn một dải màu bên trái ([accent]) để phân biệt loại nội dung
/// (từ vựng, kanji, ngữ pháp...) mà không cần tô màu cả thẻ.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = AppSpacing.card,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: margin,
      child: Material(
        color: theme.cardColor,
        borderRadius: AppRadius.mdAll,
        elevation: AppElevation.low,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accent != null)
                Container(
                  width: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.md),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
