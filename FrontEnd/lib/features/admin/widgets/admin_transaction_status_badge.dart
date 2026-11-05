import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Nhãn trạng thái của một giao dịch.
class AdminTransactionStatusBadge extends StatelessWidget {
  const AdminTransactionStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppColors.success,
      'pending' => AppColors.warning,
      'processing' => AppColors.primary,
      'failed' => AppColors.error,
      'refunded' => Colors.purple,
      _ => AppColors.neutral,
    };
    const labels = {
      'completed': 'Hoàn thành',
      'pending': 'Chờ xử lý',
      'processing': 'Đang xử lý',
      'failed': 'Thất bại',
      'refunded': 'Hoàn tiền',
      'cancelled': 'Đã hủy',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
            color: context.colors.readable(color),
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
