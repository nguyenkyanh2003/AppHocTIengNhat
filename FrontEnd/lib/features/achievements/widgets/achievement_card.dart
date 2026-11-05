import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Một huy hiệu cùng tiến độ đạt được.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.userAchievement,
  });

  final UserAchievement userAchievement;

  @override
  Widget build(BuildContext context) {
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
                      : context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isLocked ? '🔒' : achievement.icon,
                    style: const TextStyle(fontSize: AppTypography.display),
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
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.bold,
                        color: userAchievement.isCompleted
                            ? Colors.white
                            : context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.descriptionVi,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: userAchievement.isCompleted
                            ? Colors.white70
                            : context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!userAchievement.isCompleted) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: userAchievement.progressPercentage,
                          backgroundColor: context.colors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userAchievement.progress}/${achievement.requirementValue}',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: context.colors.textSecondary,
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
                          Flexible(
                            child: Text(
                              'Hoàn thành • +${achievement.xpReward} XP',
                              style: const TextStyle(
                                fontSize: AppTypography.caption,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
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
                      fontSize: AppTypography.caption,
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
        return [AppColors.rarityLegendary, AppColors.rarityLegendaryEnd];
      case 'epic':
        return [AppColors.rarityEpic, AppColors.rarityEpicEnd];
      case 'rare':
        return [AppColors.rarityRare, AppColors.rarityRareEnd];
      default:
        return [AppColors.rarityCommon, AppColors.rarityCommonEnd];
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return AppColors.rarityLegendary;
      case 'epic':
        return AppColors.rarityEpic;
      case 'rare':
        return AppColors.rarityRare;
      default:
        return AppColors.rarityCommon;
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
