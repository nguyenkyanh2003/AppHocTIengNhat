import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../providers/streak_provider.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/freeze_card.dart';
import '../widgets/streak_hero_card.dart';
import '../widgets/streak_settings_sheet.dart';
import '../widgets/xp_history_card.dart';
import '../widgets/xp_level_card.dart';

/// Chuỗi ngày, mục tiêu hôm nay, băng bảo vệ, cấp độ và lịch sử XP.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    // Tải sau frame đầu: provider báo listener ngay khi bắt đầu tải, và báo
    // giữa lúc cây đang dựng là lỗi "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    final streak = context.read<StreakProvider>();
    await Future.wait([streak.loadStreak(), streak.loadXPHistory(), streak.loadSettings()]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chuỗi ngày & XP',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Lịch học',
          onPressed: () => context.push('/streak/calendar'),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Mục tiêu & nhắc học',
          onPressed: () => showStreakSettingsSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: 'Thành tích',
          onPressed: () => context.push('/achievements'),
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined),
          tooltip: 'Bảng xếp hạng',
          onPressed: () => context.push('/leaderboard'),
        ),
      ],
      body: ContentWidthLimit(
        maxWidth: AppContentWidth.reading,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Consumer<StreakProvider>(
            builder: (context, provider, _) {
              final streak = provider.currentStreak;
              if (streak == null) {
                return provider.isLoading || provider.error == null
                    ? const Center(child: CircularProgressIndicator())
                    : _LoadError(onRetry: _loadData);
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.page,
                children: [
                  StreakHeroCard(streak: streak),
                  AppGap.md,
                  DailyGoalCard(
                    goal: streak.dailyGoal,
                    onEdit: () => showStreakSettingsSheet(context),
                  ),
                  AppGap.md,
                  FreezeCard(streak: streak),
                  AppGap.md,
                  OutlinedButton.icon(
                    onPressed: () => context.push('/streak/calendar'),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Xem lịch học'),
                  ),
                  AppGap.md,
                  XpLevelCard(streak: streak),
                  AppGap.md,
                  XpHistoryCard(history: provider.xpHistory),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.page,
      children: [
        AppGap.xl,
        const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textDisabled),
        AppGap.md,
        const Text('Không tải được dữ liệu chuỗi ngày.', textAlign: TextAlign.center),
        AppGap.md,
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Thử lại'))),
      ],
    );
  }
}
