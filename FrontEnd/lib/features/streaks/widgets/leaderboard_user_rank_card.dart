import 'package:flutter/material.dart';
import '../providers/streak_provider.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Thứ hạng của chính người dùng.
class LeaderboardUserRankCard extends StatelessWidget {
  const LeaderboardUserRankCard({
    super.key,
    required this.provider,
  });

  final StreakProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Hạng của bạn',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${provider.userRank}',
              style: TextStyle(
                color: context.colors.primary,
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
