import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import 'admin_achievement_style.dart';
import 'admin_achievement_dialogs.dart';

/// Thẻ một thành tích ở màn quản trị khổ hẹp.
class AdminAchievementCard extends StatelessWidget {
  const AdminAchievementCard({
    super.key,
    required this.achievement,
    required this.duplicateAchievement,
  });

  final Map<String, dynamic> achievement;
  final void Function(Map<String, dynamic> achievement) duplicateAchievement;

  @override
  Widget build(BuildContext context) {
    final rarityColor = achievementRarityColor(achievement['rarity']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rarityColor, width: 2),
            ),
            child: Center(
              child: Text(
                achievement['icon'],
                style: const TextStyle(fontSize: AppTypography.display),
              ),
            ),
          ),
          title: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                achievement['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTypography.body,
                ),
              ),
              _buildRarityBadge(achievement['rarity']),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(achievement['description']),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐ ${achievement['xp']} XP',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold,
                        color: context.colors.readable(Colors.purple),
                      ),
                    ),
                  ),
                  Text(
                    '${achievement['unlocked']} người đã mở',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều kiện mở khóa:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.colors.primarySoft),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: context.colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Cần đạt: ${achievement['condition']}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            showAchievementEditDialog(context, achievement),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Chỉnh sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => duplicateAchievement(achievement),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Nhân bản'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successStrong,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildRarityBadge(String rarity) {
    final color = achievementRarityColor(rarity);
    final label = achievementRarityLabel(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
