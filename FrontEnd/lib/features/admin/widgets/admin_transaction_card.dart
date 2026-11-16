import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_transaction.dart';
import 'admin_transaction_format.dart';
import 'admin_transaction_status_badge.dart';

/// Một giao dịch ở khổ hẹp.
class AdminTransactionCard extends StatelessWidget {
  const AdminTransactionCard({super.key, required this.transaction, required this.updateStatus});

  final AdminTransaction transaction;
  final void Function(AdminTransaction transaction, String status) updateStatus;

  @override
  Widget build(BuildContext context) {
    final steps = transactionNextSteps(transaction);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(transactionPaymentIcon(transaction.paymentMethod))),
        title: Row(
          children: [
            Expanded(child: Text(transaction.userName, style: const TextStyle(fontWeight: FontWeight.bold))),
            AdminTransactionStatusBadge(status: transaction.status),
          ],
        ),
        subtitle: Text('${transaction.title} • ${formatTransactionCurrency(transaction.amount)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              children: [
                _Detail('Email', transaction.userEmail.isEmpty ? '—' : transaction.userEmail),
                _Detail('Phương thức', transaction.paymentMethod),
                _Detail('Thời gian', formatTransactionDate(transaction.createdAt)),
                _Detail('Mã giao dịch', transaction.id),
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final (index, (status, label)) in steps.indexed)
                        index == 0
                            ? FilledButton(onPressed: () => updateStatus(transaction, status), child: Text(label))
                            : OutlinedButton(onPressed: () => updateStatus(transaction, status), child: Text(label)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
