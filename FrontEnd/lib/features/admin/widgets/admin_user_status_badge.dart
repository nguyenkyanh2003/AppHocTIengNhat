import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Nhãn trạng thái tài khoản.
class AdminUserStatusBadge extends StatelessWidget {
  const AdminUserStatusBadge({super.key, required this.status});

  final String status;

  static const _labels = {
    'active': 'Hoạt động',
    'inactive': 'Ngưng dùng',
    'locked': 'Tạm khoá',
    'banned': 'Bị khoá',
  };

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.success,
      'banned' || 'locked' => AppColors.error,
      _ => context.colors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: context.colors.readable(color),
        ),
      ),
    );
  }
}
