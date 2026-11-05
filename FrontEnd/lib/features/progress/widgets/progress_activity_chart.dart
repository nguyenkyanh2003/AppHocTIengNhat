import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/dashboard.dart';
import '../models/timeline_chart.dart';

/// Biểu đồ cột XP theo ngày (theo tháng ở kỳ một năm).
class ProgressActivityChart extends StatelessWidget {
  const ProgressActivityChart({
    super.key,
    required this.timeline,
    required this.period,
    this.now,
  });

  final List<TimelineData> timeline;
  final String period;

  /// Chỉ test truyền vào để cố định ngày.
  final DateTime? now;

  static const _height = 140.0;

  @override
  Widget build(BuildContext context) {
    final bars =
        chartBars(timeline, period: period, now: now ?? DateTime.now());
    final maxXp = bars.fold<int>(0, (max, bar) => bar.xp > max ? bar.xp : max);

    if (maxXp == 0) {
      return SizedBox(
        height: _height,
        child: Center(
          child: Text(
            'Chưa có hoạt động trong kỳ này',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Biểu đồ XP theo thời gian, cao nhất $maxXp XP',
      child: SizedBox(
        height: _height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final bar in bars)
              Expanded(
                child: _Bar(
                    bar: bar, ratio: bar.xp / maxXp, dense: bars.length > 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.ratio, required this.dense});

  final ChartBar bar;
  final double ratio;

  /// Nhiều cột thì nhãn phải được phép tràn ra hai bên cột, nếu không sẽ xuống dòng.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      bar.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: AppTypography.caption,
        color: context.colors.textSecondary,
      ),
    );

    return Tooltip(
      message: '${bar.xp} XP',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0 ? 0.02 : ratio,
                widthFactor: dense ? 0.7 : 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    color: ratio == 0
                        ? context.colors.surfaceVariant
                        : context.colors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: dense
                ? OverflowBox(maxWidth: 48, child: label)
                : FittedBox(fit: BoxFit.scaleDown, child: label),
          ),
        ],
      ),
    );
  }
}
