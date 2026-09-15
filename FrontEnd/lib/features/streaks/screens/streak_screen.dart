import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({Key? key}) : super(key: key);

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);
    final achievementProvider =
        Provider.of<AchievementProvider>(context, listen: false);

    await Future.wait([
      streakProvider.loadStreak(),
      streakProvider.loadXPHistory(),
      achievementProvider.loadMyAchievements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Streak & XP',
      actions: [
        IconButton(
          icon: const Icon(Icons.emoji_events),
          onPressed: () {
            context.push('/achievements');
          },
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard),
          onPressed: () {
            context.push('/leaderboard');
          },
        ),
      ],
      body: ContentWidthLimit(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Consumer<StreakProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.currentStreak == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final streak = provider.currentStreak;
              if (streak == null) {
                return const Center(
                  child: Text('Không thể tải dữ liệu streak'),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(streak, provider),
                    const SizedBox(height: 16),
                    _buildXPCard(streak),
                    const SizedBox(height: 16),
                    _buildStatsCards(streak),
                    const SizedBox(height: 16),
                    _buildXPHistory(provider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(streak, StreakProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Streak hiện tại',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: AppTypography.display),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${streak.currentStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ngày',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: AppTypography.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Kỷ lục',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppTypography.caption,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${streak.longestStreak}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTypography.headline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (streak.lastActivityDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hoạt động gần nhất: ${_formatDate(streak.lastActivityDate!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildXPCard(streak) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${streak.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tổng XP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '⭐',
                          style: TextStyle(fontSize: AppTypography.headline),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${streak.totalXP}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.headline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level tiếp theo: ${streak.xpToNextLevel} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppTypography.caption,
                      ),
                    ),
                    Text(
                      '${(streak.xpProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: streak.xpProgress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(streak) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '📚',
            'Ngày học',
            '${streak.activityDates.length}',
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🎯',
            'Trung bình/tuần',
            '${(streak.activityDates.length / 4).toStringAsFixed(1)}',
            const Color(0xFF4F46E5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String icon, String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: AppTypography.display)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: AppTypography.headline,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppTypography.caption,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPHistory(StreakProvider provider) {
    if (provider.xpHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử XP',
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.xpHistory.take(10).map((history) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('⭐', style: TextStyle(fontSize: AppTypography.title)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history.reason,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(history.earnedAt),
                            style: const TextStyle(
                              fontSize: AppTypography.caption,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${history.amount}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
