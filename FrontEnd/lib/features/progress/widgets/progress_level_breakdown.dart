import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/dashboard.dart';
import 'progress_stat_tile.dart';

/// Bài học theo cấp độ và điểm trung bình bài tập theo loại.
class ProgressLevelBreakdown extends StatelessWidget {
  const ProgressLevelBreakdown({super.key, required this.breakdown});

  final DashboardBreakdown breakdown;

  static const _typeLabels = {
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'kanji': 'Kanji',
    'listening': 'Nghe',
    'reading': 'Đọc',
    'mixed': 'Tổng hợp',
  };

  @override
  Widget build(BuildContext context) {
    final levels = breakdown.lessonsByLevel;
    final types = breakdown.exercisesByType;

    if (levels.isEmpty && types.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Text(
            'Chưa có số liệu. Học một bài hoặc làm một bài tập để xem phân tích.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (levels.isNotEmpty) ...[
              const _Caption('Bài học đã bắt đầu theo cấp độ'),
              for (final level in levels)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProgressShareBar(
                    label:
                        level.level.isEmpty ? 'Chưa đặt cấp độ' : level.level,
                    trailing: '${level.completed}/${level.total} bài',
                    ratio: level.completionRate / 100,
                    color: AppColors.success,
                  ),
                ),
            ],
            if (types.isNotEmpty) ...[
              const _Caption('Điểm trung bình theo loại bài tập'),
              for (final type in types)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProgressShareBar(
                    label:
                        '${_typeLabels[type.type] ?? type.type} · ${type.count} lần',
                    trailing: '${type.averageScore.toStringAsFixed(1)}%',
                    ratio: type.averageScore / 100,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
