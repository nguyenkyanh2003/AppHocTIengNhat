import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/dashboard.dart';
import '../models/timeline_chart.dart';
import '../providers/progress_provider.dart';
import '../widgets/progress_activity_chart.dart';
import '../widgets/progress_level_breakdown.dart';
import '../widgets/progress_period_selector.dart';
import '../widgets/progress_stat_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../streaks/models/user_streak.dart';

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({super.key});

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<StreakProvider>().loadStreak(),
      context.read<ProgressProvider>().loadDashboardData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final streak = context.watch<StreakProvider>();

    return AppScaffold(
      title: 'Thống kê chi tiết',
      body: AsyncView<ProgressDashboard>(
        state: progress.dashboard,
        onRetry: _loadData,
        builder: (context, dashboard) {
          final period = TimelineSummary.of(dashboard.timeline);
          final stats = dashboard.stats;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ContentPane(
                maxWidth: AppContentWidth.dashboard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Heading('Trong kỳ'),
                    ProgressPeriodSelector(provider: progress),
                    AppGap.md,
                    ResponsiveGrid(
                      children: [
                        ProgressStatTile(
                          icon: Icons.star,
                          label: 'XP nhận được',
                          value: '${period.xp}',
                          color: AppColors.warning,
                        ),
                        ProgressStatTile(
                          icon: Icons.menu_book,
                          label: 'Bài học đã học',
                          value: '${period.lessons}',
                          color: AppColors.success,
                        ),
                        ProgressStatTile(
                          icon: Icons.quiz,
                          label: 'Bài tập đã nộp',
                          value: '${period.exercises}',
                          color: AppColors.primary,
                        ),
                        ProgressStatTile(
                          icon: Icons.timer,
                          label: 'Thời gian làm bài',
                          value: formatStudySeconds(period.seconds),
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    AppGap.lg,
                    Card(
                      child: Padding(
                        padding: AppSpacing.card,
                        child: ProgressActivityChart(
                          timeline: dashboard.timeline,
                          period: progress.selectedPeriod,
                        ),
                      ),
                    ),
                    const _Heading('Tổng cộng'),
                    ResponsiveGrid(
                      children: [
                        ProgressStatTile(
                          icon: Icons.menu_book,
                          label: 'Bài học hoàn thành',
                          value: '${stats.lessonsCompleted}',
                          color: AppColors.success,
                        ),
                        ProgressStatTile(
                          icon: Icons.spellcheck,
                          label: 'Từ vựng đã học',
                          value: '${stats.vocabularyLearned}',
                          color: AppColors.warning,
                        ),
                        ProgressStatTile(
                          icon: Icons.draw_outlined,
                          label: 'Kanji đã học',
                          value: '${stats.kanjiLearned}',
                          color: AppColors.error,
                        ),
                        ProgressStatTile(
                          icon: Icons.access_time,
                          label: 'Thời gian làm bài',
                          value: stats.formattedStudyTime,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const _Heading('Chuỗi học'),
                    AsyncView<UserStreak>(
                      state: streak.streakState,
                      compact: true,
                      onRetry: streak.loadStreak,
                      builder: (context, value) => ResponsiveGrid(
                        children: [
                          ProgressStatTile(
                            icon: Icons.local_fire_department,
                            label: 'Chuỗi hiện tại',
                            value: '${value.currentStreak} ngày',
                            color: AppColors.error,
                          ),
                          ProgressStatTile(
                            icon: Icons.trending_up,
                            label: 'Chuỗi dài nhất',
                            value: '${value.longestStreak} ngày',
                            color: AppColors.primary,
                          ),
                          ProgressStatTile(
                            icon: Icons.star,
                            label: 'Tổng XP',
                            value: '${value.totalXP}',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                    const _Heading('Phân tích chi tiết'),
                    ProgressLevelBreakdown(breakdown: dashboard.breakdown),
                    AppGap.xl,
                    OutlinedButton.icon(
                      onPressed: () => context.push('/export'),
                      icon: const Icon(Icons.download),
                      label: const Text('Xuất dữ liệu học tập'),
                    ),
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
          fontSize: AppTypography.subtitle,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
