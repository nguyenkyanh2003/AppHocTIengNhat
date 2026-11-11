import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/achievement.dart';
import 'achievement_rarity.dart';

/// Một huy hiệu cùng tiến độ: đã đạt thì nền đặc theo độ hiếm, còn khoá thì có thanh
/// tiến độ.
class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key, required this.userAchievement});

  final UserAchievement userAchievement;

  @override
  Widget build(BuildContext context) {
    final item = userAchievement;
    final achievement = item.achievement;
    final done = item.isCompleted;
    final onFill = done ? Colors.white : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      elevation: done ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: AppSpacing.page,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: done
              ? LinearGradient(
                  colors: achievementRarityFill(achievement.rarity),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeIcon(item: item),
            AppGap.lg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.displayName,
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.bold,
                      color: onFill ?? context.colors.textPrimary,
                    ),
                  ),
                  AppGap.xs,
                  Text(
                    achievement.displayDescription,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: onFill ?? context.colors.textSecondary,
                    ),
                  ),
                  AppGap.sm,
                  if (done)
                    _EarnedLine(item: item)
                  else
                    _ProgressLine(item: item),
                  AppGap.sm,
                  AchievementRarityChip(achievement.rarity, onFill: done),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.item});

  final UserAchievement item;

  @override
  Widget build(BuildContext context) {
    final done = item.isCompleted;

    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? Colors.white.withValues(alpha: 0.2)
            : context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: done
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.achievement.icon,
                style: const TextStyle(fontSize: AppTypography.display),
              ),
            )
          : Icon(Icons.lock_outline, color: context.colors.textSecondary),
    );
  }
}

class _EarnedLine extends StatelessWidget {
  const _EarnedLine({required this.item});

  final UserAchievement item;

  @override
  Widget build(BuildContext context) {
    final earnedAt = item.earnedAt;
    final parts = [
      'Hoàn thành',
      '+${item.achievement.xpReward} XP',
      if (earnedAt != null) DateFormat('dd/MM/yyyy').format(earnedAt),
    ];

    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        AppGap.xs,
        Expanded(
          child: Text(
            parts.join(' • '),
            style: const TextStyle(
              fontSize: AppTypography.caption,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.item});

  final UserAchievement item;

  @override
  Widget build(BuildContext context) {
    final achievement = item.achievement;
    final style = TextStyle(
      fontSize: AppTypography.caption,
      color: context.colors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: item.completionRatio,
            backgroundColor: context.colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            minHeight: 6,
          ),
        ),
        AppGap.xs,
        Text(
          item.isReadyToClaim
              ? 'Đã đủ điều kiện, sẽ nhận ở lần học tiếp theo'
              : '${item.progress}/${achievement.requirementValue} • +${achievement.xpReward} XP',
          style: style,
        ),
      ],
    );
  }
}
