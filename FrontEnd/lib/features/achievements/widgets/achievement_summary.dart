import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/achievement.dart';

/// Ba con số đầu màn Thành tích, lấy thẳng từ server.
class AchievementSummary extends StatelessWidget {
  const AchievementSummary({super.key, required this.achievements});

  final MyAchievements achievements;

  @override
  Widget build(BuildContext context) {
    final percent = (achievements.completionRate * 100).round();

    return Container(
      padding: AppSpacing.page,
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.emoji_events_outlined,
            value: '${achievements.completed}/${achievements.total}',
            label: 'Đã đạt',
          ),
          _SummaryItem(
            icon: Icons.donut_large,
            value: '$percent%',
            label: 'Hoàn thành',
          ),
          _SummaryItem(
            icon: Icons.lock_outline,
            value: '${achievements.locked.length}',
            label: 'Chưa mở',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: context.colors.primaryStrong),
          AppGap.xs,
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
