import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/dashboard.dart';
import '../models/timeline_chart.dart';
import '../providers/progress_provider.dart';
import 'progress_activity_chart.dart';
import 'progress_period_selector.dart';
import 'progress_stat_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';

/// Tab Thống kê của màn Lịch sử học.
class HistoryStatsTab extends StatelessWidget {
  const HistoryStatsTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return AsyncView<ProgressDashboard>(
      state: provider.dashboard,
      onRetry: onRefresh,
      builder: (context, dashboard) {
        final today = _dayKey(DateTime.now());
        final todayRows = dashboard.timeline.where((day) => day.date == today);
        final summary = TimelineSummary.of(dashboard.timeline);

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressPeriodSelector(provider: provider),
                AppGap.lg,
                _Section(
                  title: 'Thời gian làm bài',
                  child: ResponsiveGrid(
                    minTileWidth: 150,
                    children: [
                      ProgressStatTile(
                        icon: Icons.today,
                        label: 'Hôm nay',
                        value: formatStudySeconds(
                            TimelineSummary.of(todayRows).seconds),
                        color: AppColors.primary,
                      ),
                      ProgressStatTile(
                        icon: Icons.date_range,
                        label: progressPeriods[provider.selectedPeriod] ?? '',
                        value: formatStudySeconds(summary.seconds),
                        color: AppColors.success,
                      ),
                      ProgressStatTile(
                        icon: Icons.access_time,
                        label: 'Tổng cộng',
                        value: dashboard.stats.formattedStudyTime,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                AppGap.lg,
                _Section(
                  title: 'XP theo thời gian',
                  child: ProgressActivityChart(
                    timeline: dashboard.timeline,
                    period: provider.selectedPeriod,
                  ),
                ),
                AppGap.lg,
                _Section(
                  title: 'Đã học được',
                  child: _LearnedShare(stats: dashboard.stats),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppGap.lg,
            child,
          ],
        ),
      ),
    );
  }
}

/// Tỉ lệ giữa các mục đã học, tính từ số thật của tài khoản.
class _LearnedShare extends StatelessWidget {
  const _LearnedShare({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Từ vựng', stats.vocabularyLearned, AppColors.primary),
      ('Kanji', stats.kanjiLearned, AppColors.error),
      ('Bài học', stats.lessonsCompleted, AppColors.success),
      ('Bài tập', stats.exercisesCompleted, AppColors.warning),
    ];
    final total = rows.fold<int>(0, (sum, row) => sum + row.$2);
    if (total == 0) {
      return Text(
        'Chưa có số liệu. Hoàn thành bài học đầu tiên để xem phân bố.',
        style: TextStyle(color: context.colors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final (label, count, color) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ProgressShareBar(
              label: label,
              trailing: '$count',
              ratio: count / total,
              color: color,
            ),
          ),
      ],
    );
  }
}
