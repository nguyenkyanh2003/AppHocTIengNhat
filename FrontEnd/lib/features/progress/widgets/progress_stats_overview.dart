import 'package:flutter/material.dart';
import '../providers/progress_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Lưới số liệu tổng quan ở đầu màn Tiến độ.
class ProgressStatsOverview extends StatelessWidget {
  const ProgressStatsOverview({
    super.key,
    required this.provider,
  });

  final ProgressProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê tổng quan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            // Số cột tính từ chỗ trống thật của vùng nội dung; bề rộng cửa sổ
            // không trừ rail nên dùng nó sẽ ra thừa một cột trên desktop.
            crossAxisCount: (constraints.maxWidth ~/ 220).clamp(2, 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            // Chiều cao cố định: tỉ lệ làm thẻ cao vống lên khi cột rộng ra.
            childAspectRatio: 1.6,
            children: [
              _buildStatCard(
                context,
                '📚',
                'Từ vựng',
                '${stats.vocabularyLearned}',
                AppColors.primary,
              ),
              _buildStatCard(
                context,
                '🔤',
                'Kanji',
                '${stats.kanjiReviewing}',
                Colors.purple,
              ),
              _buildStatCard(
                context,
                '✏️',
                'Bài tập',
                '${stats.exercisesCompleted}',
                AppColors.success,
              ),
              _buildStatCard(
                context,
                '📖',
                'Bài học',
                '${stats.lessonsCompleted}',
                AppColors.warning,
              ),
              _buildStatCard(
                context,
                '⏱️',
                'Thời gian',
                stats.formattedStudyTime,
                AppColors.error,
              ),
              _buildStatCard(
                context,
                '🔥',
                'Streak',
                '${stats.currentStreak} ngày',
                Colors.deepOrange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String label,
      String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: AppTypography.title)),
            const SizedBox(height: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                    color: context.colors.readable(color),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
