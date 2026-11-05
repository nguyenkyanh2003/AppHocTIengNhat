import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

Color achievementRarityColor(String rarity) {
  switch (rarity) {
    case 'common':
      return AppColors.neutral;
    case 'rare':
      return AppColors.primary;
    case 'epic':
      return Colors.purple;
    case 'legendary':
      return AppColors.warning;
    default:
      return AppColors.neutral;
  }
}

String achievementRarityLabel(String rarity) {
  switch (rarity) {
    case 'common':
      return 'COMMON';
    case 'rare':
      return 'RARE';
    case 'epic':
      return 'EPIC';
    case 'legendary':
      return 'LEGENDARY';
    default:
      return rarity.toUpperCase();
  }
}
