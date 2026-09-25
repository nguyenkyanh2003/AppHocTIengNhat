import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/user_streak.dart';

/// Câu mô tả trạng thái hôm nay.
///
/// Không bao giờ khẳng định chuỗi "sẽ đứt": người học có thể còn học trước nửa
/// đêm, và băng có thể che ngày nghỉ (spec §5.3). Chỉ nói điều đã chắc.
String streakStatusMessage(UserStreak streak) {
  if (streak.studiedToday) return 'Hôm nay bạn đã học. Làm tốt lắm!';
  if (streak.lastActivityDay == null) return 'Học bài đầu tiên để bắt đầu chuỗi ngày.';
  if (streak.currentStreak == 0) return 'Chuỗi đã dừng. Học hôm nay để bắt đầu lại.';
  if (streak.pendingFreezes > 0) {
    return 'Bạn đã nghỉ ${streak.pendingFreezes} ngày. Học hôm nay để băng che những ngày đó.';
  }
  return 'Hôm nay bạn chưa học.';
}

/// Chuỗi hiện tại, kỷ lục, số ngày đã học và trạng thái hôm nay.
class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key, required this.streak});

  final UserStreak streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.streak,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: AppTypography.display)),
                AppGap.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.currentStreak} ngày liên tiếp',
                        style: AppTypography.heroDisplay(
                          size: AppTypography.headline,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Kỷ lục ${streak.longestStreak} ngày · Đã học ${streak.totalActiveDays} ngày',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppGap.md,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.35),
                borderRadius: AppRadius.mdAll,
              ),
              child: Text(
                streakStatusMessage(streak),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
