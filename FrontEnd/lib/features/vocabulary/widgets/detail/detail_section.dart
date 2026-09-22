import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// Khung chung cho mọi khối của màn chi tiết từ vựng: nền trắng, bo góc lớn,
/// bóng mềm, không viền — để các khối đứng cạnh nhau như một bộ.
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.lgAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: AppSpacing.xl,
            offset: const Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.xl, color: AppColors.primary),
                  AppGap.sm,
                ],
                Expanded(
                  child: Text(title!, style: theme.textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            AppGap.lg,
          ],
          child,
        ],
      ),
    );
  }
}
