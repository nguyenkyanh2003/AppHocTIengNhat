import 'package:flutter/material.dart';
import 'admin_transaction_format.dart';
import 'admin_transaction_status_badge.dart';

/// Một giao dịch ở khổ hẹp.
class AdminTransactionCard extends StatelessWidget {
  const AdminTransactionCard({
    super.key,
    required this.transaction,
    required this.updateStatus,
  });

  final Map<String, dynamic> transaction;
  final Future<void> Function(String id, String status) updateStatus;

  @override
  Widget build(BuildContext context) {
    final user = transaction['user'] is Map
        ? Map<String, dynamic>.from(transaction['user'])
        : <String, dynamic>{};
    final status = transaction['status']?.toString() ?? 'pending';
    final name = user['HoTen'] ?? user['TenDangNhap'] ?? 'Người dùng';
    final id = transaction['_id']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
            child: Text(transactionPaymentIcon(transaction['payment_method']))),
        title: Row(
          children: [
            Expanded(
              child: Text(name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            AdminTransactionStatusBadge(status: status),
          ],
        ),
        subtitle: Text(
          '${transaction['package_id'] ?? transaction['type'] ?? 'Giao dịch'} • ${formatTransactionCurrency(transaction['amount'] as num? ?? 0)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _detail('Email', user['Email']?.toString() ?? '—'),
                _detail('Phương thức',
                    transaction['payment_method']?.toString() ?? 'NONE'),
                _detail('Thời gian',
                    formatTransactionDate(transaction['createdAt'])),
                _detail('Mã giao dịch', id.isEmpty ? '—' : id),
                if (status == 'pending' || status == 'processing') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: id.isEmpty
                              ? null
                              : () => updateStatus(id, 'completed'),
                          icon: const Icon(Icons.check),
                          label: const Text('Xác nhận'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: id.isEmpty
                              ? null
                              : () => updateStatus(id, 'failed'),
                          icon: const Icon(Icons.close),
                          label: const Text('Từ chối'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'completed') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        id.isEmpty ? null : () => updateStatus(id, 'refunded'),
                    icon: const Icon(Icons.undo),
                    label: const Text('Đánh dấu hoàn tiền'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
