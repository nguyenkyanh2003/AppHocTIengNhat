import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/achievement_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'all',
    'vocabulary',
    'grammar',
    'kanji',
    'lesson',
    'streak',
    'xp',
    'practice',
  ];

  final Map<String, String> _categoryNames = {
    'all': 'Tất cả',
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'kanji': 'Kanji',
    'lesson': 'Bài học',
    'streak': 'Streak',
    'xp': 'Kinh nghiệm',
    'practice': 'Luyện tập',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AchievementProvider>(context, listen: false);
    await Future.wait([
      provider.loadMyAchievements(),
      provider.loadStats(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Thành tích',
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _categories.map((cat) {
          return Tab(text: _categoryNames[cat]);
        }).toList(),
      ),
      body: ContentWidthLimit(
        child: Consumer<AchievementProvider>(
          builder: (context, provider, child) {
            final all = [
              ...provider.earnedAchievements,
              ...provider.lockedAchievements,
            ];
            return AsyncView<List<UserAchievement>>(
              state: ViewState.fromLegacy(
                isLoading: provider.isLoading,
                error: provider.error,
                value: all,
                isEmpty: all.isEmpty,
              ),
              onRetry: _loadData,
              isEmpty: (items) => items.isEmpty,
              emptyTitle: 'Chưa có thành tích nào',
              emptyIcon: Icons.emoji_events_outlined,
              builder: (context, _) => Column(
                children: [
                  _buildStatsHeader(provider),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _categories.map((category) {
                        return _buildAchievementList(provider, category);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader(AchievementProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: context.colors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '🏆',
            '${provider.completedAchievements}/${provider.totalAchievements}',
            'Đã đạt',
          ),
          _buildStatItem(
            '📊',
            '${(provider.completionRate * 100).toStringAsFixed(0)}%',
            'Hoàn thành',
          ),
          _buildStatItem(
            '🔓',
            '${provider.lockedAchievements.length}',
            'Chưa mở',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: AppTypography.headline)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList(AchievementProvider provider, String category) {
    List<UserAchievement> achievements;

    if (category == 'all') {
      achievements = [
        ...provider.earnedAchievements,
        ...provider.lockedAchievements
      ];
    } else {
      achievements = provider.getAchievementsByCategory(category);
    }

    if (achievements.isEmpty) {
      return const EmptyStateView(
        title: 'Chưa có thành tích nào',
        icon: Icons.emoji_events_outlined,
      );
    }

    // Sort: completed first, then by progress
    achievements.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? -1 : 1;
      }
      return b.progress.compareTo(a.progress);
    });

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          return AchievementCard(userAchievement: achievements[index]);
        },
      ),
    );
  }
}
