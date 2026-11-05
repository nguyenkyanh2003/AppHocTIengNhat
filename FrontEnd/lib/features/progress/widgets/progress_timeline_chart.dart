import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/progress_provider.dart';
import 'progress_period_selector.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Biểu đồ bài tập và bài học theo ngày của kỳ đang chọn.
class ProgressTimelineChart extends StatelessWidget {
  const ProgressTimelineChart({
    super.key,
    required this.provider,
  });

  final ProgressProvider provider;

  @override
  Widget build(BuildContext context) {
    final timeline = provider.timeline;
    final peak = timeline.fold<int>(0, (max, day) {
      final top = day.exercises > day.lessons ? day.exercises : day.lessons;
      return top > max ? top : max;
    });
    // Số nguyên trên trục: đỉnh nhỏ mà để mặc định thì nhãn lặp "0 0 0 1".
    final yInterval = (peak / 5).ceil().clamp(1, 1000000).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            const Text(
              'Biểu đồ học tập',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildPeriodSelector(context, provider),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: timeline.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có hoạt động trong kỳ này',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                      fontSize: AppTypography.caption),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= timeline.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = timeline[value.toInt()].dateTime;
                                return Text(
                                  DateFormat('dd/MM').format(date),
                                  style: const TextStyle(
                                      fontSize: AppTypography.caption),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: timeline
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.exercises.toDouble(),
                                    ))
                                .toList(),
                            isCurved: true,
                            color: context.colors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: timeline
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.lessons.toDouble(),
                                    ))
                                .toList(),
                            isCurved: true,
                            color: AppColors.warning,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.warning.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _buildLegendItem(AppColors.primary, 'Bài tập'),
              _buildLegendItem(AppColors.warning, 'Bài học'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ProgressProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: provider.selectedPeriod,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'week', child: Text('Tuần')),
          DropdownMenuItem(value: 'month', child: Text('Tháng')),
          DropdownMenuItem(value: 'year', child: Text('Năm')),
        ],
        onChanged: (value) {
          if (value != null) {
            changeProgressPeriod(context, provider, value);
          }
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: AppTypography.caption),
        ),
      ],
    );
  }
}
