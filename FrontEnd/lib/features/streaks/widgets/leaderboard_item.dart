import 'package:flutter/material.dart';
import '../models/leaderboard.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Một dòng trên bảng xếp hạng.
class LeaderboardItem extends StatelessWidget {
  const LeaderboardItem({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  static const _avatarMinWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isTopThree
              ? LinearGradient(
                  colors: _getRankGradient(entry.rank),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Điện thoại rất hẹp thì bỏ ảnh đại diện, nhường chỗ cho tên và số liệu.
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                // Rank badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isTopThree
                        ? Colors.white.withValues(alpha: 0.3)
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getRankIcon(entry.rank),
                      style: TextStyle(
                        fontSize: isTopThree ? 28 : 20,
                        fontWeight: FontWeight.bold,
                        color: isTopThree
                            ? _onMedal(entry.rank)
                            : context.colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Avatar
                if (constraints.maxWidth >= _avatarMinWidth) ...[
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: isTopThree
                        ? Colors.white.withValues(alpha: 0.3)
                        : context.colors.border,
                    child: entry.avatar != null
                        ? ClipOval(
                            child: Image.network(
                              entry.avatar!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  entry.avatarInitial,
                                  style: TextStyle(
                                    fontSize: AppTypography.title,
                                    fontWeight: FontWeight.bold,
                                    color: isTopThree
                                        ? _onMedal(entry.rank)
                                        : context.colors.textSecondary,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            entry.avatarInitial,
                            style: TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.bold,
                              color: isTopThree
                                  ? _onMedal(entry.rank)
                                  : context.colors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                          color: isTopThree
                              ? _onMedal(entry.rank)
                              : context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _buildInfoChip(context, '🔥 ${entry.currentStreak}',
                              entry.rank, isTopThree),
                          _buildInfoChip(context, 'Lv.${entry.level}',
                              entry.rank, isTopThree),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.totalXP}',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                        color: isTopThree
                            ? _onMedal(entry.rank)
                            : context.colors.primary,
                      ),
                    ),
                    Text(
                      'XP',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: isTopThree
                            ? _onMedal(entry.rank).withValues(alpha: 0.7)
                            : context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chữ trên thẻ huy chương: vàng và bạc rất sáng nên dùng mực đậm, đồng tối hơn nên dùng trắng.
  Color _onMedal(int rank) => rank == 3 ? Colors.white : AppColors.ink;

  Widget _buildInfoChip(
      BuildContext context, String text, int rank, bool isTopThree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTopThree
            ? Colors.white.withValues(alpha: 0.2)
            : context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: isTopThree ? _onMedal(rank) : context.colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [AppColors.medalGold, AppColors.medalGoldEnd];
      case 2:
        return [AppColors.medalSilver, AppColors.medalSilverEnd];
      case 3:
        return [AppColors.medalBronze, AppColors.medalBronzeEnd];
      default:
        return [AppColors.neutral, AppColors.neutral];
    }
  }
}
