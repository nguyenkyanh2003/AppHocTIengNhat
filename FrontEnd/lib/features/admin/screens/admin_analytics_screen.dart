import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/admin_analytics_chart.dart';
import '../widgets/admin_level_distribution.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/responsive_grid.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalytics());
  }

  Future<void> _loadAnalytics() =>
      context.read<AdminProvider>().loadAnalytics(period: _selectedPeriod);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Phân tích học tập',
      actions: [
        IconButton(
          onPressed: _loadAnalytics,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final analytics = provider.analytics ?? const <String, dynamic>{};
            if (analytics.isEmpty) {
              return AsyncView<Map<String, dynamic>>(
                state: ViewState.detail(
                  isLoading: provider.isLoadingAnalytics,
                  error: provider.error,
                  value: provider.analytics,
                ),
                onRetry: _loadAnalytics,
                builder: (context, _) => const SizedBox.shrink(),
              );
            }
            final labels = _strings(analytics['labels']);
            return RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _periodSelector(),
                  const SizedBox(height: 20),
                  _metrics(analytics['metrics']),
                  const SizedBox(height: 20),
                  AdminAnalyticsChart(
                      title: 'Người dùng hoạt động',
                      icon: Icons.people,
                      color: AppColors.primary,
                      labels: labels,
                      values: _numbers(analytics['daily_active_users'])),
                  AdminAnalyticsChart(
                      title: 'Đăng ký mới',
                      icon: Icons.person_add,
                      color: AppColors.success,
                      labels: labels,
                      values: _numbers(analytics['new_registrations'])),
                  AdminAnalyticsChart(
                      title: 'Bài học hoàn thành',
                      icon: Icons.school,
                      color: AppColors.warning,
                      labels: labels,
                      values: _numbers(analytics['lessons_completed'])),
                  AdminAnalyticsChart(
                      title: 'Thời gian học (phút)',
                      icon: Icons.timer,
                      color: Colors.purple,
                      labels: labels,
                      values: _numbers(analytics['total_study_time'])),
                  AdminLevelDistribution(
                      rawDistribution: analytics['level_distribution']),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    const periods = {'7d': '7 ngày', '30d': '30 ngày', '90d': '90 ngày'};
    return Wrap(
      spacing: 8,
      children: periods.entries.map((entry) {
        return ChoiceChip(
          label: Text(entry.value),
          selected: _selectedPeriod == entry.key,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _selectedPeriod = entry.key);
            _loadAnalytics();
          },
        );
      }).toList(),
    );
  }

  Widget _metrics(dynamic rawMetrics) {
    final values = rawMetrics is Map
        ? Map<String, dynamic>.from(rawMetrics)
        : <String, dynamic>{};
    return ResponsiveGrid(
      minTileWidth: 150,
      children: [
        _metric('Tổng người dùng', values['total_users'], Icons.people,
            AppColors.primary),
        _metric(
          'Hoạt động hôm nay',
          values['active_today'],
          Icons.trending_up,
          AppColors.success,
        ),
        _metric(
          'Bài học hoàn thành',
          values['lessons_completed'],
          Icons.school,
          AppColors.warning,
        ),
        _metric(
          'Tổng phút học',
          values['study_minutes'],
          Icons.timer,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _metric(String label, dynamic value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.colors.readable(color)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${value ?? 0}',
                style: const TextStyle(
                    fontSize: AppTypography.headline,
                    fontWeight: FontWeight.bold),
              ),
              Text(label,
                  style: const TextStyle(fontSize: AppTypography.caption)),
            ],
          ),
        ),
      );

  List<String> _strings(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];

  List<num> _numbers(dynamic value) => value is List
      ? value
          .map((item) => item is num ? item : num.tryParse('$item') ?? 0)
          .toList()
      : const [];
}
