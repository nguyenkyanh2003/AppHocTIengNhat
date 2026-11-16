import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/admin_report.dart';
import '../providers/admin_reports_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_report_card.dart';
import '../widgets/admin_report_style.dart';
import '../widgets/admin_report_table.dart';

/// Báo cáo người học gửi lên. [service] chỉ để test truyền service giả.
class AdminReportManagementScreen extends StatelessWidget {
  const AdminReportManagementScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminReportsProvider(service: service)..load(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminReportsProvider>();

    return AppScaffold(
      title: 'Quản lý báo cáo',
      actions: [
        IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: provider.load),
        IconButton(
          tooltip: 'Lọc theo loại',
          icon: Icon(provider.type == null ? Icons.filter_list : Icons.filter_alt),
          onPressed: () => _pickType(context, provider),
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            AsyncView<AdminReportStats>(
              state: provider.stats,
              compact: true,
              builder: (context, stats) => AdminReportStatsBar(stats: stats),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(label: 'Tất cả', status: null, provider: provider),
                  for (final MapEntry(:key, :value) in AdminReportStatus.labels.entries)
                    _StatusChip(label: value, status: key, provider: provider),
                ],
              ),
            ),
            if (provider.isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: AsyncView<List<AdminReport>>(
                state: provider.reports,
                onRetry: provider.load,
                isEmpty: (reports) => reports.isEmpty,
                emptyTitle: 'Không có báo cáo nào',
                emptyIcon: Icons.flag_outlined,
                builder: (context, reports) => AdaptiveTable<AdminReport>(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  items: reports,
                  onRefresh: provider.load,
                  rowKey: (item) => ValueKey(item.report.id),
                  columns: adminReportColumns(),
                  cardBuilder: (context, item) => AdminReportCard(item: item),
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

  void _pickType(BuildContext context, AdminReportsProvider provider) {
    final options = <(String?, String)>[
      (null, 'Tất cả'),
      for (final MapEntry(:key, :value) in AdminReportsProvider.types.entries) (key, value),
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Lọc theo loại báo cáo'),
        children: [
          for (final (type, label) in options)
            ListTile(
              title: Text(label),
              trailing: provider.type == type ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(dialogContext);
                provider.selectType(type);
              },
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status, required this.provider});

  final String label;

  /// `null` là mọi trạng thái.
  final String? status;
  final AdminReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final selected = provider.status == status;
    final color = status == null ? context.colors.textSecondary : AdminReportStatus.colorOf(status!);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => provider.selectStatus(status),
        selectedColor: color.withValues(alpha: 0.3),
        labelStyle: TextStyle(
          color: selected ? context.colors.readable(color) : context.colors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
