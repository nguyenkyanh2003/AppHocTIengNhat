import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../streaks/providers/streak_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/history_activity_tab.dart';
import '../widgets/history_overview_tab.dart';
import '../widgets/history_stats_tab.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final streak = context.read<StreakProvider>();
    await Future.wait([
      streak.loadStreak(),
      streak.loadXPHistory(),
      context.read<ProgressProvider>().loadDashboardData(),
      context.read<AchievementProvider>().loadMyAchievements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lịch sử học tập',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Hoạt động'),
          Tab(text: 'Thống kê'),
        ],
      ),
      body: ContentWidthLimit(
        child: TabBarView(
          controller: _tabController,
          children: [
            HistoryOverviewTab(onRefresh: _loadData),
            HistoryActivityTab(onRefresh: _loadData),
            HistoryStatsTab(onRefresh: _loadData),
          ],
        ),
      ),
    );
  }
}
