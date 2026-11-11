import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_achievement.dart';

/// Ba con số đầu màn quản trị thành tích.
class AdminAchievementSummary extends StatelessWidget {
  const AdminAchievementSummary({super.key, required this.achievements});

  final List<AdminAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.fold<int>(0, (sum, a) => sum + a.unlocked);
    final hidden = achievements.where((a) => !a.definition.isActive).length;

    return Container(
      padding: AppSpacing.page,
      color: context.colors.surfaceVariant,
      child: Row(
        children: [
          _SummaryItem(value: '${achievements.length}', label: 'Tổng'),
          _SummaryItem(value: '$unlocked', label: 'Lượt mở khoá'),
          _SummaryItem(value: '$hidden', label: 'Đang ẩn'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
              color: context.colors.primaryStrong,
            ),
          ),
          AppGap.xs,
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
