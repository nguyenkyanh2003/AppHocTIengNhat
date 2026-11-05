import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/admin_dashboard_summary.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_dashboard_widgets.dart';
import '../../../shared/widgets/responsive_grid.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return AppScaffold(
      title: 'Bảng điều khiển',
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
          onPressed: provider.loadDashboardStats,
        ),
      ],
      body: AsyncView<Map<String, dynamic>>(
        state: ViewState.fromLegacy(
          isLoading: provider.isLoadingStats,
          error: provider.error,
          value:
              provider.dashboardStats.isEmpty ? null : provider.dashboardStats,
        ),
        onRetry: provider.loadDashboardStats,
        builder: (context, stats) {
          final summary = AdminDashboardSummary.fromStats(stats);
          return RefreshIndicator(
            onRefresh: provider.loadDashboardStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ContentPane(
                maxWidth: AppContentWidth.dashboard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Overview(summary: summary),
                    const _Heading('Quản lý nhanh'),
                    const _QuickActions(),
                    const _Heading('Hoạt động gần đây'),
                    if (summary.activities.isEmpty)
                      Text(
                        'Chưa có hoạt động nào.',
                        style: TextStyle(color: context.colors.textSecondary),
                      )
                    else
                      for (final activity in summary.activities)
                        AdminActivityTile(activity: activity),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ResponsiveGrid(
        children: [
          AdminStatTile(
            icon: Icons.people,
            value: '${summary.totalUsers}',
            label: 'Người dùng',
          ),
          AdminStatTile(
            icon: Icons.school,
            value: '${summary.totalLessons}',
            label: 'Bài học',
          ),
          AdminStatTile(
            icon: Icons.flag,
            value: '${summary.pendingReports}',
            label: 'Báo cáo chờ xử lý',
          ),
          AdminStatTile(
            icon: Icons.bolt,
            value: '${summary.activeToday}',
            label: 'Hoạt động hôm nay',
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    AdminActionCard tile(String title, String subtitle, Color color,
            IconData icon, String path) =>
        AdminActionCard(
          title: title,
          subtitle: subtitle,
          color: color,
          icon: icon,
          onTap: () => context.push(path),
        );

    return ResponsiveGrid(
      minTileWidth: 170,
      children: [
        tile('Người dùng', 'Tài khoản và phân quyền', AppColors.primary,
            Icons.people, '/admin/users'),
        tile('Nội dung', 'Bài học, từ vựng, kanji', AppColors.success,
            Icons.library_books, '/admin/content'),
        tile('Báo cáo', 'Phản hồi từ người học', AppColors.warning, Icons.flag,
            '/admin/reports'),
        tile('Thành tích', 'Huy hiệu và điều kiện', Colors.purple,
            Icons.emoji_events, '/admin/achievements'),
        tile('Giao dịch', 'Lịch sử thanh toán', AppColors.info,
            Icons.receipt_long, '/admin/transactions'),
        tile('Thống kê', 'Hoạt động hệ thống', AppColors.error, Icons.analytics,
            '/admin/analytics'),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.title,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
