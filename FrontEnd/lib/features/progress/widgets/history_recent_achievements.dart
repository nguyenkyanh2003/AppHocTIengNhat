import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../../shared/widgets/async_view.dart';

/// Ba thành tích mở khoá gần nhất của chính người dùng.
class HistoryRecentAchievements extends StatelessWidget {
  const HistoryRecentAchievements({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Thành tích gần đây',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/achievements'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            AsyncView<List<UserAchievement>>(
              state: provider.earnedState,
              compact: true,
              onRetry: provider.loadMyAchievements,
              builder: (context, earned) {
                final recent = earned.where((item) => item.isCompleted).toList()
                  ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
                if (recent.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'Chưa mở khoá thành tích nào. Học thêm để nhận huy hiệu đầu tiên!',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in recent.take(3))
                      _AchievementRow(item: item),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.item});

  final UserAchievement item;

  @override
  Widget build(BuildContext context) {
    final achievement = item.achievement;
    final title =
        achievement.nameVi.isNotEmpty ? achievement.nameVi : achievement.name;
    final description = achievement.descriptionVi.isNotEmpty
        ? achievement.descriptionVi
        : achievement.description;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Text(achievement.icon,
              style: const TextStyle(fontSize: AppTypography.title)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypography.bodySmall,
                  ),
                ),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '+${achievement.xpReward} XP',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
