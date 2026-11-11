import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/achievement.dart';
import '../models/achievement_labels.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_summary.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  /// Tab đầu (`null`) là tất cả, sau đó mỗi nhóm một tab.
  static final List<String?> _categories = [
    null,
    ...achievementCategoryLabels.keys,
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AchievementProvider>().loadMyAchievements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final error =
        await context.read<AchievementProvider>().loadMyAchievements();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();

    return AppScaffold(
      title: 'Thành tích',
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          for (final category in _categories)
            Tab(text: achievementCategoryLabels[category] ?? 'Tất cả'),
        ],
      ),
      body: ContentWidthLimit(
        child: AsyncView<MyAchievements>(
          state: provider.mine,
          onRetry: provider.loadMyAchievements,
          isEmpty: (mine) => mine.isEmpty,
          emptyTitle: 'Chưa có thành tích nào',
          emptyIcon: Icons.emoji_events_outlined,
          builder: (context, mine) => Column(
            children: [
              AchievementSummary(achievements: mine),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final category in _categories)
                      _AchievementList(
                        items: mine.inCategory(category),
                        onRefresh: _refresh,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementList extends StatelessWidget {
  const _AchievementList({required this.items, required this.onRefresh});

  final List<UserAchievement> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyStateView(
        title: 'Nhóm này chưa có thành tích nào',
        icon: Icons.emoji_events_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: AppSpacing.page,
        itemCount: items.length,
        itemBuilder: (context, index) =>
            AchievementCard(userAchievement: items[index]),
      ),
    );
  }
}
