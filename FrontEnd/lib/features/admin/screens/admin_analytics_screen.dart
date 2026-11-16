import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../models/admin_analytics.dart';
import '../providers/admin_analytics_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_analytics_chart.dart';
import '../widgets/admin_level_distribution.dart';

/// Hoạt động học toàn hệ thống theo kỳ. [service] chỉ để test truyền service giả.
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAnalyticsProvider(service: service)..load(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAnalyticsProvider>();

    return AppScaffold(
      title: 'Phân tích học tập',
      actions: [
        IconButton(onPressed: provider.load, icon: const Icon(Icons.refresh), tooltip: 'Tải lại'),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final MapEntry(:key, :value) in AdminAnalyticsProvider.periods.entries)
                      ChoiceChip(
                        label: Text(value),
                        selected: provider.period == key,
                        onSelected: (selected) {
                          if (selected) provider.selectPeriod(key);
                        },
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AsyncView<AdminAnalytics>(
                state: provider.analytics,
                onRetry: provider.load,
                builder: (context, analytics) => RefreshIndicator(
                  onRefresh: provider.load,
                  child: _AnalyticsBody(analytics: analytics),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.analytics});

  final AdminAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    AdminAnalyticsChart chart(String title, IconData icon, Color color, List<num> values) =>
        AdminAnalyticsChart(title: title, icon: icon, color: color, labels: analytics.labels, values: values);

    return ListView(
      padding: AppSpacing.page,
      children: [
        ResponsiveGrid(
          minTileWidth: 150,
          children: [
            _Metric('Tổng người dùng', analytics.totalUsers, Icons.people, AppColors.primary),
            _Metric('Hoạt động hôm nay', analytics.activeToday, Icons.trending_up, AppColors.success),
            _Metric('Bài học hoàn thành', analytics.lessonsCompleted, Icons.school, AppColors.warning),
            _Metric('Tổng phút học', analytics.studyMinutes, Icons.timer, Colors.purple),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        chart('Người dùng hoạt động', Icons.people, AppColors.primary, analytics.dailyActiveUsers),
        chart('Đăng ký mới', Icons.person_add, AppColors.success, analytics.newRegistrations),
        chart('Bài học hoàn thành', Icons.school, AppColors.warning, analytics.dailyLessonsCompleted),
        chart('Thời gian học (phút)', Icons.timer, Colors.purple, analytics.dailyStudyMinutes),
        AdminLevelDistribution(distribution: analytics.levelDistribution),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.readable(color)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$value',
              style: const TextStyle(fontSize: AppTypography.headline, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: AppTypography.caption)),
          ],
        ),
      ),
    );
  }
}
