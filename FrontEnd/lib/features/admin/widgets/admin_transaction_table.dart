import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_table.dart';
import '../models/admin_transaction.dart';
import 'admin_transaction_format.dart';
import 'admin_transaction_status_badge.dart';

/// Cột bảng giao dịch trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
List<AdaptiveColumn<AdminTransaction>> adminTransactionColumns({
  required void Function(AdminTransaction transaction, String status) updateStatus,
}) =>
    [
      AdaptiveColumn(
        label: 'Người dùng',
        minWidth: 200,
        cell: (context, tx) => Text(tx.userName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Gói',
        minWidth: 160,
        cell: (context, tx) => Text(tx.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Số tiền',
        width: 130,
        alignEnd: true,
        cell: (context, tx) => Text(formatTransactionCurrency(tx.amount)),
      ),
      AdaptiveColumn(
        label: 'Thời gian',
        width: 150,
        cell: (context, tx) => Text(formatTransactionDate(tx.createdAt)),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 130,
        cell: (context, tx) => Align(
          alignment: Alignment.centerLeft,
          child: AdminTransactionStatusBadge(status: tx.status),
        ),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, tx) {
          final steps = transactionNextSteps(tx);
          if (steps.isEmpty) return const SizedBox.shrink();
          return PopupMenuButton<String>(
            tooltip: 'Thao tác',
            onSelected: (status) => updateStatus(tx, status),
            itemBuilder: (context) => [
              for (final (status, label) in steps) PopupMenuItem(value: status, child: Text(label)),
            ],
          );
        },
      ),
    ];
