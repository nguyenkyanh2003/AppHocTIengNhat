import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => _loadForStatus(_selectedStatus),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final transactions = provider.transactions;
          if (provider.isLoadingTransactions && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => _loadForStatus(_selectedStatus),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummary(transactions),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 12),
                if (provider.error != null && transactions.isEmpty)
                  _buildError(provider.error!)
                else if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('Chưa có giao dịch nào.')),
                  )
                else
                  ...transactions.map(_buildTransactionCard),
              ],
            ),
          );
        },
      ),
    );
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
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _stat('Đang hiển thị', '${transactions.length}')),
            Expanded(child: _stat('Chờ duyệt', '$pending')),
            Expanded(child: _stat('Đã thu', _formatCurrency(revenue))),
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
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

  Widget _buildError(String message) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _loadForStatus(_selectedStatus),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
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
            child: Text(_paymentIcon(transaction['payment_method']))),
        title: Row(
          children: [
            Expanded(
              child: Text(name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            _statusBadge(status),
          ],
        ),
        subtitle: Text(
          '${transaction['package_id'] ?? transaction['type'] ?? 'Giao dịch'} • ${_formatCurrency(transaction['amount'] as num? ?? 0)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _detail('Email', user['Email']?.toString() ?? '—'),
                _detail('Phương thức',
                    transaction['payment_method']?.toString() ?? 'NONE'),
                _detail('Thời gian', _formatDate(transaction['createdAt'])),
                _detail('Mã giao dịch', id.isEmpty ? '—' : id),
                if (status == 'pending' || status == 'processing') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: id.isEmpty
                              ? null
                              : () => _updateStatus(id, 'completed'),
                          icon: const Icon(Icons.check),
                          label: const Text('Xác nhận'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: id.isEmpty
                              ? null
                              : () => _updateStatus(id, 'failed'),
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
                        id.isEmpty ? null : () => _updateStatus(id, 'refunded'),
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

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'completed' => Colors.green,
      'pending' => Colors.orange,
      'processing' => Colors.blue,
      'failed' => Colors.red,
      'refunded' => Colors.purple,
      _ => Colors.grey,
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
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatCurrency(num amount) {
    final value = amount.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return '$value đ';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _paymentIcon(dynamic method) => switch (method?.toString()) {
        'MOMO' => 'M',
        'VNPAY' => 'V',
        'BANK' => 'B',
        'CARD' => 'C',
        _ => '₫',
      };

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
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
