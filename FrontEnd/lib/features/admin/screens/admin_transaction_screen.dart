import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/admin_transaction.dart';
import '../providers/admin_transactions_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_transaction_card.dart';
import '../widgets/admin_transaction_format.dart';
import '../widgets/admin_transaction_table.dart';

/// Duyệt giao dịch và xem lịch sử thanh toán. [service] chỉ để test truyền
/// service giả.
class AdminTransactionScreen extends StatelessWidget {
  const AdminTransactionScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminTransactionsProvider(service: service)..load(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  Future<void> _updateStatus(BuildContext context, AdminTransaction transaction, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminTransactionsProvider>().updateStatus(transaction, status);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? 'Đã cập nhật giao dịch.'),
      backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminTransactionsProvider>();
    void update(AdminTransaction transaction, String status) => _updateStatus(context, transaction, status);

    // Phần tổng quan và bộ lọc không cuộn cùng danh sách: khi danh sách
    // chuyển sang dạng bảng, header cột phải dính lại chứ không trôi theo.
    return AppScaffold(
      title: 'Quản lý giao dịch',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), tooltip: 'Tải lại', onPressed: provider.load),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _Summary(transactions: provider.transactions.valueOrNull ?? const []),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusFilter(provider: provider),
                ],
              ),
            ),
            if (provider.isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: AsyncView<List<AdminTransaction>>(
                state: provider.transactions,
                onRetry: provider.load,
                isEmpty: (items) => items.isEmpty,
                emptyTitle: 'Chưa có giao dịch nào',
                emptyIcon: Icons.receipt_long_outlined,
                builder: (context, items) => AdaptiveTable<AdminTransaction>(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  items: items,
                  onRefresh: provider.load,
                  rowKey: (tx) => ValueKey(tx.id),
                  columns: adminTransactionColumns(updateStatus: update),
                  cardBuilder: (context, tx) => AdminTransactionCard(transaction: tx, updateStatus: update),
                  paging: TablePaging(
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    error: provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đếm trên các giao dịch đang hiện (theo bộ lọc và số trang đã tải).
class _Summary extends StatelessWidget {
  const _Summary({required this.transactions});

  final List<AdminTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final pending = transactions.where((tx) => tx.isOpen).length;
    final revenue = transactions
        .where((tx) => tx.status == 'completed')
        .fold<num>(0, (sum, tx) => sum + tx.amount);
    return Card(
      color: AppColors.success,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(child: _Stat('Đang hiển thị', '${transactions.length}')),
            Expanded(child: _Stat('Chờ duyệt', '$pending')),
            Expanded(child: _Stat('Đã thu', formatTransactionCurrency(revenue))),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: const TextStyle(fontSize: AppTypography.caption, color: AppColors.ink)),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.provider});

  final AdminTransactionsProvider provider;

  @override
  Widget build(BuildContext context) {
    final options = <(String?, String)>[
      (null, 'Tất cả'),
      for (final MapEntry(:key, :value) in AdminTransactionsProvider.statuses.entries) (key, value),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (status, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(label),
                selected: provider.status == status,
                onSelected: (_) => provider.selectStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}
