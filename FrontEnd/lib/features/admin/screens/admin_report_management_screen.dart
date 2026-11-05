import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/admin_report_dialogs.dart';
import '../widgets/admin_report_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportManagementScreen> createState() =>
      _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState
    extends State<AdminReportManagementScreen> {
  String _selectedStatus = 'all';
  String _selectedType = 'all';

  static const _types = {
    'all': 'Tất cả',
    'bug': 'Lỗi ứng dụng',
    'content': 'Nội dung',
    'suggestion': 'Góp ý',
    'other': 'Khác',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản Lý Reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminProvider>().loadReports(),
        ),
        IconButton(
          tooltip: 'Lọc theo loại',
          icon: Icon(
            _selectedType == 'all' ? Icons.filter_list : Icons.filter_alt,
          ),
          onPressed: _showFilterDialog,
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final allReports = adminProvider.reports;

            final filteredReports = allReports.where((report) {
              final matchesStatus = _selectedStatus == 'all' ||
                  report['status'] == _selectedStatus;
              final matchesType =
                  _selectedType == 'all' || report['type'] == _selectedType;
              return matchesStatus && matchesType;
            }).toList();

            return Column(
              children: [
                // Stats Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.colors.surfaceVariant,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                          '${allReports.length}', 'Tổng', AppColors.primary),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'pending').length}',
                          'Chờ xử lý',
                          AppColors.warning),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'in_progress').length}',
                          'Đang xử lý',
                          Colors.purple),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'resolved').length}',
                          'Đã xong',
                          AppColors.success),
                    ],
                  ),
                ),

                // Status Filter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip(
                            'Tất cả', 'all', context.colors.textSecondary),
                        _buildStatusChip(
                            'Chờ xử lý', 'pending', AppColors.warning),
                        _buildStatusChip(
                            'Đang xử lý', 'in_progress', Colors.purple),
                        _buildStatusChip(
                            'Đã xong', 'resolved', AppColors.success),
                      ],
                    ),
                  ),
                ),

                // Reports List
                Expanded(
                  child: AsyncView<List<Map<String, dynamic>>>(
                    state: ViewState.fromLegacy(
                      isLoading: adminProvider.isLoadingReports,
                      error: allReports.isEmpty ? adminProvider.error : null,
                      value: filteredReports,
                      isEmpty: filteredReports.isEmpty,
                    ),
                    onRetry: () => adminProvider.loadReports(),
                    isEmpty: (reports) => reports.isEmpty,
                    emptyTitle: 'Không có báo cáo nào',
                    emptyIcon: Icons.flag_outlined,
                    builder: (context, filteredReports) =>
                        AdaptiveTable<Map<String, dynamic>>(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      items: filteredReports,
                      rowKey: (report) =>
                          ValueKey(report['_id'] ?? report['id']),
                      columns: _reportColumns(),
                      cardBuilder: (context, report) => AdminReportCard(
                          report: report, updateStatus: _updateStatus),
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

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = value);
        },
        selectedColor: color.withValues(alpha: 0.3),
        backgroundColor: context.colors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected
              ? context.colors.readable(color)
              : context.colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Cot bang bao cao tren vung rong; cung du lieu voi the o man hep.
  List<AdaptiveColumn<Map<String, dynamic>>> _reportColumns() {
    return [
      AdaptiveColumn(
        label: 'Tiêu đề',
        minWidth: 240,
        cell: (context, report) => Text(
          (report['title'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Loại',
        width: 130,
        cell: (context, report) => Text((report['type'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 130,
        cell: (context, report) => Text((report['status'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, report) => IconButton(
          tooltip: 'Phản hồi',
          icon: const Icon(Icons.reply),
          onPressed: () => showAdminReportResponseDialog(context, report),
        ),
      ),
    ];
  }

  Future<void> _updateStatus(
    Map<String, dynamic> report,
    String newStatus,
  ) async {
    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final id = (report['id'] ?? report['_id']).toString();
    final success = await provider.respondToReport(id, '', newStatus);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Đã cập nhật trạng thái.'
            : provider.error ?? 'Không cập nhật được trạng thái.'),
        backgroundColor:
            success ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Lọc theo loại báo cáo'),
        children: [
          for (final MapEntry(:key, :value) in _types.entries)
            ListTile(
              title: Text(value),
              trailing: _selectedType == key ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _selectedType = key);
                Navigator.pop(dialogContext);
              },
            ),
        ],
      ),
    );
  }
}
