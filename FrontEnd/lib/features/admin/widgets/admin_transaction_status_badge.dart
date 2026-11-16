import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../providers/admin_transactions_provider.dart';
import 'admin_report_style.dart';

/// Nhãn trạng thái của một giao dịch.
class AdminTransactionStatusBadge extends StatelessWidget {
  const AdminTransactionStatusBadge({super.key, required this.status});

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
    return AdminBadge(label: AdminTransactionsProvider.statuses[status] ?? status, color: color);
  }
}
