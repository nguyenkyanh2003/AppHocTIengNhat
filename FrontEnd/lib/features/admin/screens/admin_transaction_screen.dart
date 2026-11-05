import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/admin_transaction_format.dart';
import '../widgets/admin_transaction_card.dart';

class AdminTransactionScreen extends StatefulWidget {
  const AdminTransactionScreen({super.key});

  @override
  State<AdminTransactionScreen> createState() => _AdminTransactionScreenState();
}

class _AdminTransactionScreenState extends State<AdminTransactionScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý giao dịch',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
          onPressed: () => _loadForStatus(_selectedStatus),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final transactions = provider.transactions;
            // Phần tổng quan và bộ lọc không cuộn cùng danh sách nữa: khi
            // danh sách chuyển sang dạng bảng, header cột phải dính lại chứ
            // không trôi mất theo nội dung.
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildSummary(transactions),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFilters(),
                    ],
                  ),
                ),
                Expanded(
                  child: AsyncView<List<Map<String, dynamic>>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoadingTransactions,
                      error: provider.error,
                      value: transactions,
                      isEmpty: transactions.isEmpty,
                    ),
                    onRetry: () => _loadForStatus(_selectedStatus),
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: 'Chưa có giao dịch nào',
                    emptyIcon: Icons.receipt_long_outlined,
                    builder: (context, items) =>
                        AdaptiveTable<Map<String, dynamic>>(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      items: items,
                      onRefresh: () => _loadForStatus(_selectedStatus),
                      rowKey: (tx) => ValueKey(tx['_id'] ?? tx['id']),
                      columns: _transactionColumns(),
                      cardBuilder: (context, tx) => AdminTransactionCard(
                          transaction: tx, updateStatus: _updateStatus),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Cot bang giao dich tren vung rong; cung du lieu voi the o man hep.
  List<AdaptiveColumn<Map<String, dynamic>>> _transactionColumns() {
    return [
      AdaptiveColumn(
        label: 'Người dùng',
        minWidth: 200,
        cell: (context, tx) {
          final user = tx['user'];
          final name = user is Map ? (user['name'] ?? user['email']) : user;
          return Text(
            (name ?? '—').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      AdaptiveColumn(
        label: 'Gói',
        minWidth: 160,
        cell: (context, tx) => Text(
          (tx['package_id'] ?? tx['type'] ?? '—').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Số tiền',
        width: 130,
        alignEnd: true,
        cell: (context, tx) => Text((tx['amount'] ?? 0).toString()),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 130,
        cell: (context, tx) => Text((tx['status'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 96,
        alignEnd: true,
        cell: (context, tx) {
          final id = (tx['_id'] ?? tx['id'])?.toString();
          if (id == null) return const SizedBox.shrink();
          return PopupMenuButton<String>(
            onSelected: (status) => _updateStatus(id, status),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'completed', child: Text('Đánh dấu xong')),
              PopupMenuItem(value: 'failed', child: Text('Đánh dấu thất bại')),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildSummary(List<Map<String, dynamic>> transactions) {
    final completed =
        transactions.where((item) => item['status'] == 'completed');
    final revenue = completed.fold<num>(
      0,
      (sum, item) => sum + ((item['amount'] as num?) ?? 0),
    );
    final pending =
        transactions.where((item) => item['status'] == 'pending').length;
    return Card(
      color: AppColors.success,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _stat('Đang hiển thị', '${transactions.length}')),
            Expanded(child: _stat('Chờ duyệt', '$pending')),
            Expanded(
                child: _stat('Đã thu', formatTransactionCurrency(revenue))),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.bold,
                color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: AppTypography.caption, color: AppColors.ink)),
        ],
      );

  Widget _buildFilters() {
    const filters = {
      'all': 'Tất cả',
      'pending': 'Chờ xử lý',
      'processing': 'Đang xử lý',
      'completed': 'Hoàn thành',
      'failed': 'Thất bại',
      'refunded': 'Hoàn tiền',
      'cancelled': 'Đã hủy',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: _selectedStatus == entry.key,
              onSelected: (_) {
                setState(() => _selectedStatus = entry.key);
                _loadForStatus(entry.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadForStatus(String status) =>
      context.read<AdminProvider>().loadTransactions(
            status: status == 'all' ? null : status,
          );

  Future<void> _updateStatus(String id, String status) async {
    final success =
        await context.read<AdminProvider>().updateTransactionStatus(id, status);
    if (!mounted) return;
    if (success && _selectedStatus != 'all') {
      await _loadForStatus(_selectedStatus);
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? 'Đã cập nhật giao dịch.' : 'Cập nhật thất bại.'),
        backgroundColor:
            success ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }
}
