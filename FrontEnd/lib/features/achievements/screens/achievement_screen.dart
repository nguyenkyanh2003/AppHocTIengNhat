import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

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
    _loadData();
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
            if (provider.isLoading && provider.earnedAchievements.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
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
          bottom: BorderSide(color: Colors.grey[300]!),
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
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🏆',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thành tích nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
          return _buildAchievementCard(achievements[index]);
        },
      ),
    );
  }

  Widget _buildAchievementCard(UserAchievement userAchievement) {
    final achievement = userAchievement.achievement;
    final isLocked = userAchievement.isLocked || !userAchievement.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: userAchievement.isCompleted ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: userAchievement.isCompleted
              ? LinearGradient(
                  colors: _getRarityGradient(achievement.rarity),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: userAchievement.isCompleted
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isLocked ? '🔒' : achievement.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.nameVi,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: userAchievement.isCompleted
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.descriptionVi,
                      style: TextStyle(
                        fontSize: 13,
                        color: userAchievement.isCompleted
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!userAchievement.isCompleted) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: userAchievement.progressPercentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userAchievement.progress}/${achievement.requirementValue}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hoàn thành • +${achievement.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: userAchievement.isCompleted
                        ? Colors.white.withValues(alpha: 0.2)
                        : _getRarityColor(achievement.rarity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRarityText(achievement.rarity),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: userAchievement.isCompleted
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getRarityGradient(String rarity) {
    switch (rarity) {
      case 'legendary':
        return [const Color(0xFFFFD700), const Color(0xFFFFAA00)];
      case 'epic':
        return [const Color(0xFF9C27B0), const Color(0xFF673AB7)];
      case 'rare':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      default:
        return [const Color(0xFF757575), const Color(0xFF616161)];
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'rare':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getRarityText(String rarity) {
    switch (rarity) {
      case 'legendary':
        return 'HUYỀN THOẠI';
      case 'epic':
        return 'SỬ THI';
      case 'rare':
        return 'HIẾM';
      default:
        return 'THƯỜNG';
    }
  }
}
