import 'package:flutter/material.dart';
import '../providers/progress_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_theme.dart';

/// Phân tích bài học theo cấp độ và bài tập theo loại.
class ProgressBreakdownCharts extends StatelessWidget {
  const ProgressBreakdownCharts({
    super.key,
    required this.provider,
  });

  final ProgressProvider provider;

  @override
  Widget build(BuildContext context) {
    final breakdown = provider.breakdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân tích chi tiết',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Show empty state when no data
        if (breakdown == null ||
            (breakdown.lessonsByLevel.isEmpty &&
                breakdown.exercisesByType.isEmpty)) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 64, color: context.colors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu phân tích',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu học bài và làm bài tập để xem phân tích chi tiết',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
        ]

        // Show breakdown data
        else ...[
          if (breakdown.lessonsByLevel.isNotEmpty) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bài học theo cấp độ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...breakdown.lessonsByLevel.map((level) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(level.level),
                                Text(
                                  '${level.completed}/${level.total}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: level.completionRate / 100,
                              backgroundColor: context.colors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.getJlptLevelColor(level.level),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (breakdown.exercisesByType.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bài tập theo loại',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...breakdown.exercisesByType.map((type) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(type.type),
                          child: Text(
                            type.count.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(type.type),
                        subtitle: Text(
                          'Điểm TB: ${type.averageScore.toStringAsFixed(1)}',
                        ),
                        trailing: Text(
                          '${type.passRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: type.passRate >= 70
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ], // Close the else block for breakdown data
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Từ vựng':
        return AppColors.primary;
      case 'Ngữ pháp':
        return Colors.purple;
      case 'Kanji':
        return AppColors.warning;
      case 'Tổng hợp':
        return AppColors.success;
      default:
        return AppColors.neutral;
    }
  }
}
