import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/calm_colors.dart';
import '../models/xp_reward.dart';

/// Khối "+5 XP" dưới kết quả bài tập / đề JLPT, cùng bảng màu với thẻ XP ở
/// trang chủ, và nói rõ làm lại còn được gì: người học không phải đoán vì sao
/// lượt này 0 XP.
class XpRewardNote extends StatelessWidget {
  const XpRewardNote({super.key, required this.reward, required this.subject});

  final XpReward reward;

  /// "bài này" hoặc "đề này".
  final String subject;

  String get _title => reward.awarded > 0 ? '+${reward.awarded} XP' : 'Không cộng thêm XP';

  String get _detail {
    if (reward.remaining > 0) return 'Làm đạt $subject để nhận thêm ${reward.remaining} XP.';
    if (reward.awarded > 0) return 'Làm lại $subject sẽ không cộng thêm XP.';
    return 'Bạn đã nhận đủ XP của $subject; lượt này vẫn được tính là ngày học.';
  }

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: calm.xpCard, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: calm.xpIconBg, borderRadius: AppRadius.mdAll),
            child: Icon(Icons.star_outline_rounded, color: calm.xpIcon),
          ),
          AppGap.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppTypography.ui(size: AppTypography.subtitle, weight: FontWeight.w700, color: calm.xpValue),
                ),
                AppGap.xs,
                Text(
                  _detail,
                  style: AppTypography.ui(size: AppTypography.bodySmall, weight: FontWeight.w500, color: calm.xpLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
