import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Nhãn trạng thái tài khoản.
class AdminUserStatusBadge extends StatelessWidget {
  const AdminUserStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = AppColors.success;
        text = 'Active';
        break;
      case 'banned':
        color = AppColors.error;
        text = 'Banned';
        break;
      default:
        color = context.colors.textSecondary;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: context.colors.readable(color),
        ),
      ),
    );
  }
}
