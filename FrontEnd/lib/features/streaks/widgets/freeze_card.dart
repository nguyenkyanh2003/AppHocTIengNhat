import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/day_key.dart';
import '../models/user_streak.dart';

/// Câu dự báo lần tiêu băng khi người học quay lại; `null` khi không có gì chờ.
///
/// Tách "đã ghi" với "dự kiến" (spec §5.2): kho hiển thị là kho đã ghi, còn
/// câu này nói rõ là dự kiến. Chuỗi đã đứt thì băng vẫn bị dùng cho các ngày
/// đầu — nói thẳng ra thay vì để người học tưởng băng vẫn còn nguyên.
String? pendingFreezeMessage(UserStreak streak) {
  if (streak.pendingFreezes == 0) return null;
  final days = streak.pendingFrozenDays.map(formatDayKey).join(', ');
  if (streak.currentStreak == 0) {
    return 'Dự kiến: khi bạn học lại, ${streak.pendingFreezes} băng vẫn được dùng cho '
        '$days nhưng không đủ giữ chuỗi.';
  }
  return 'Dự kiến: khi bạn học lại, ${streak.pendingFreezes} băng sẽ che $days.';
}

/// Kho băng bảo vệ chuỗi và cách nhận thêm.
class FreezeCard extends StatelessWidget {
  const FreezeCard({super.key, required this.streak});

  final UserStreak streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = pendingFreezeMessage(streak);

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.ac_unit, color: AppColors.freeze),
                AppGap.sm,
                Expanded(child: Text('Băng bảo vệ chuỗi', style: theme.textTheme.titleMedium)),
                Semantics(
                  label: 'Đang có ${streak.freezesAvailable} trên ${streak.maxFreezes} băng',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      for (var slot = 0; slot < streak.maxFreezes; slot++)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.ac_unit,
                            size: 20,
                            color: slot < streak.freezesAvailable ? AppColors.freeze : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            AppGap.sm,
            Text(
              '${streak.freezesAvailable}/${streak.maxFreezes} băng đang có',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (pending != null) ...[
              AppGap.sm,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.freeze.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Text(pending, style: theme.textTheme.bodySmall),
              ),
            ],
            AppGap.sm,
            Text(
              'Mỗi băng che một ngày nghỉ. Nhận 1 băng khi chuỗi chạm 7, 14, 30, 50, 100 '
              'và 365 ngày; giữ tối đa ${streak.maxFreezes} băng.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
