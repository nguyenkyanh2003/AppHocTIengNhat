import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../achievements/models/achievement_labels.dart';
import '../../achievements/widgets/achievement_rarity.dart';
import '../models/admin_achievement.dart';
import 'admin_achievement_dialogs.dart';

/// Thẻ một thành tích ở màn quản trị khổ hẹp.
class AdminAchievementCard extends StatelessWidget {
  const AdminAchievementCard({super.key, required this.achievement});

  final AdminAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final definition = achievement.definition;
    final rarityColor = achievementRarityFill(definition.rarity).first;
    final caption = TextStyle(
      fontSize: AppTypography.caption,
      color: context.colors.textSecondary,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rarityColor.withValues(alpha: 0.1),
              rarityColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rarityColor, width: 2),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                definition.icon,
                style: const TextStyle(fontSize: AppTypography.display),
              ),
            ),
          ),
          title: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                definition.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTypography.body,
                ),
              ),
              AchievementRarityChip(definition.rarity),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(definition.displayDescription),
                AppGap.xs,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text('+${definition.xpReward} XP', style: caption),
                    Text('${achievement.unlocked} người đã mở', style: caption),
                    if (!definition.isActive)
                      Text(
                        'Đang ẩn',
                        style: caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${achievementCriterionLabels[definition.category] ?? 'Cần đạt'}: '
                    '${definition.requirementValue}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AppGap.lg,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => showAchievementFormDialog(
                          context,
                          initial: definition,
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Chỉnh sửa'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showAchievementFormDialog(
                          context,
                          initial: definition,
                          asCopy: true,
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Nhân bản'),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: () =>
                            confirmDeleteAchievement(context, achievement),
                        icon: Icon(Icons.delete, color: context.colors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
