import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/achievement_labels.dart';

/// Hai màu của nền thẻ theo độ hiếm. Mọi màu đều đạt 4,5:1 với chữ trắng.
List<Color> achievementRarityFill(String rarity) => switch (rarity) {
      'legendary' => const [
          AppColors.rarityLegendary,
          AppColors.rarityLegendaryEnd
        ],
      'epic' => const [AppColors.rarityEpic, AppColors.rarityEpicEnd],
      'rare' => const [AppColors.rarityRare, AppColors.rarityRareEnd],
      _ => const [AppColors.rarityCommon, AppColors.rarityCommonEnd],
    };

/// Nhãn độ hiếm, dùng chung cho màn người học và màn quản trị.
class AchievementRarityChip extends StatelessWidget {
  const AchievementRarityChip(this.rarity, {super.key, this.onFill = false});

  final String rarity;

  /// Nằm trên thẻ nền đặc: thẻ giữ màu ở cả hai chế độ nên nhãn nền trắng.
  final bool onFill;

  @override
  Widget build(BuildContext context) {
    final hue = achievementRarityFill(rarity).first;
    final colors = context.colors;
    final tint = Color.alphaBlend(hue.withValues(alpha: 0.15), colors.surface);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: onFill ? Colors.white : tint,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        achievementRarityLabel(rarity),
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: onFill ? hue : colors.readable(hue, on: tint),
        ),
      ),
    );
  }
}
