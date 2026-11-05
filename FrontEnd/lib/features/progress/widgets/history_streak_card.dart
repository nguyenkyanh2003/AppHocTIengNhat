import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../streaks/models/user_streak.dart';

/// Chuỗi ngày, kỷ lục, tổng XP và tiến độ lên cấp.
class HistoryStreakCard extends StatelessWidget {
  const HistoryStreakCard({super.key, required this.streak});

  final UserStreak streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.historyHeroStart, AppColors.historyHeroEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  _StatItem(
                    icon: Icons.local_fire_department,
                    value: '${streak.currentStreak}',
                    label: 'Ngày liên tiếp',
                    iconColor: AppColors.warning,
                  ),
                  const VerticalDivider(color: Colors.white24, width: 1),
                  _StatItem(
                    icon: Icons.emoji_events,
                    value: '${streak.longestStreak}',
                    label: 'Kỷ lục',
                    iconColor: Colors.amber,
                  ),
                  const VerticalDivider(color: Colors.white24, width: 1),
                  _StatItem(
                    icon: Icons.star,
                    value: '${streak.totalXP}',
                    label: 'Tổng XP',
                    iconColor: Colors.yellow,
                  ),
                ],
              ),
            ),
            AppGap.lg,
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  'Level ${streak.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${streak.xpToNextLevel} XP đến level tiếp theo',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: AppTypography.caption,
                  ),
                ),
              ],
            ),
            AppGap.sm,
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: streak.xpProgress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
