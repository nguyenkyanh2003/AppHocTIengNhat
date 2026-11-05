import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/hub_tile.dart';
import '../models/dashboard.dart';
import '../providers/progress_provider.dart';
import '../widgets/progress_breakdown_charts.dart';
import '../widgets/progress_heatmap_calendar.dart';
import '../widgets/progress_stats_overview.dart';
import '../widgets/progress_timeline_chart.dart';
import '../../../shared/widgets/responsive_grid.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProgressProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return AppScaffold(
      title: 'Tiến độ học tập',
      actions: [
        IconButton(
          tooltip: 'Mục tiêu học tập',
          icon: const Icon(Icons.flag_outlined),
          onPressed: () => context.push('/goals'),
        ),
      ],
      // `ContentPane` nằm **trong** vùng cuộn nên thanh cuộn ở mép ngoài;
      // không bọc thêm `ContentWidthLimit` vì như vậy là hẹp hai lần.
      body: AsyncView<ProgressDashboard>(
        state: provider.dashboard,
        onRetry: provider.loadDashboardData,
        builder: (context, _) => RefreshIndicator(
          onRefresh: provider.loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ContentPane(
              maxWidth: AppContentWidth.dashboard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProgressLinks(),
                  const SizedBox(height: AppSpacing.xl),
                  ProgressStatsOverview(provider: provider),
                  const SizedBox(height: AppSpacing.xl),
                  ProgressTimelineChart(provider: provider),
                  const SizedBox(height: AppSpacing.xl),
                  ProgressBreakdownCharts(provider: provider),
                  const SizedBox(height: AppSpacing.xl),
                  ProgressHeatmapCalendar(provider: provider),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lối vào hai màn xem sâu hơn từ trang Tiến độ.
class _ProgressLinks extends StatelessWidget {
  const _ProgressLinks();

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minTileWidth: 280,
      children: [
        HubTile(
          label: 'Lịch sử học',
          subtitle: 'Hoạt động và XP theo ngày',
          icon: Icons.history,
          color: AppColors.primary,
          onTap: () => context.push('/learning-history'),
        ),
        HubTile(
          label: 'Thống kê chi tiết',
          subtitle: 'Số liệu theo kỳ và cấp độ',
          icon: Icons.bar_chart,
          color: AppColors.progress,
          onTap: () => context.push('/statistics'),
        ),
      ],
    );
  }
}
