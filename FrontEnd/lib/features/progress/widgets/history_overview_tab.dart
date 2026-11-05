import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/dashboard.dart';
import '../providers/progress_provider.dart';
import 'history_streak_card.dart';
import 'progress_stat_tile.dart';
import 'history_week_calendar.dart';
import 'history_recent_achievements.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../streaks/models/user_streak.dart';

/// Tab Tổng quan của màn Lịch sử học.
class HistoryOverviewTab extends StatelessWidget {
  const HistoryOverviewTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakProvider>();
    final progress = context.watch<ProgressProvider>();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AsyncView<UserStreak>(
              state: streak.streakState,
              compact: true,
              onRetry: streak.loadStreak,
              builder: (context, value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HistoryStreakCard(streak: value),
                  AppGap.lg,
                  HistoryWeekCalendar(streak: value),
                ],
              ),
            ),
            AppGap.lg,
            AsyncView<ProgressDashboard>(
              state: progress.dashboard,
              compact: true,
              onRetry: progress.loadDashboardData,
              builder: (context, dashboard) =>
                  _LearnedTotals(stats: dashboard.stats),
            ),
            AppGap.lg,
            const HistoryRecentAchievements(),
          ],
        ),
      ),
    );
  }
}

class _LearnedTotals extends StatelessWidget {
  const _LearnedTotals({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minTileWidth: 150,
      children: [
        ProgressStatTile(
          icon: Icons.book,
          label: 'Từ vựng đã học',
          value: '${stats.vocabularyLearned}',
          color: AppColors.primary,
        ),
        ProgressStatTile(
          icon: Icons.draw_outlined,
          label: 'Kanji đang ôn',
          value: '${stats.kanjiReviewing}',
          color: AppColors.error,
        ),
        ProgressStatTile(
          icon: Icons.quiz,
          label: 'Bài tập đã nộp',
          value: '${stats.exercisesCompleted}',
          color: AppColors.success,
        ),
      ],
    );
  }
}
