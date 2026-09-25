import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/user_streak.dart';

/// Cấp độ, tổng XP và phần còn thiếu để lên cấp.
class XpLevelCard extends StatelessWidget {
  const XpLevelCard({super.key, required this.streak});

  final UserStreak streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: AppTypography.title)),
                AppGap.sm,
                Expanded(child: Text('Cấp ${streak.level}', style: theme.textTheme.titleMedium)),
                Text(
                  '${streak.totalXP} XP',
                  style: AppTypography.heroDisplay(size: AppTypography.subtitle, color: AppColors.accent),
                ),
              ],
            ),
            AppGap.sm,
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: streak.xpProgress,
                minHeight: AppSpacing.sm,
                color: AppColors.accent,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                semanticsLabel: 'Tiến độ lên cấp',
              ),
            ),
            AppGap.xs,
            Text('Còn ${streak.xpToNextLevel} XP để lên cấp ${streak.level + 1}.',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
