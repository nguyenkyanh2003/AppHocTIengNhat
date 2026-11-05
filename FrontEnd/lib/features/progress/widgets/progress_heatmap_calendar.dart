import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/progress_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/dashboard.dart';

/// Lịch hoạt động cả năm dạng ô màu.
class ProgressHeatmapCalendar extends StatelessWidget {
  const ProgressHeatmapCalendar({
    super.key,
    required this.provider,
  });

  final ProgressProvider provider;

  @override
  Widget build(BuildContext context) {
    final heatmap = provider.heatmap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch học tập',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Show loading state
        if (heatmap.isEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 64, color: context.colors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử học tập',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học tập đều đặn để xây dựng lịch sử của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
        ]

        // Show heatmap data
        else ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ProgressHeatmapGrid(heatmap: heatmap),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ô lịch cả năm kèm chú giải. Màu từng mức lấy từ `context.colors.heatmap`, ô và chú
/// giải dùng cùng một nguồn nên không thể lệch nhau.
class ProgressHeatmapGrid extends StatelessWidget {
  const ProgressHeatmapGrid({super.key, required this.heatmap});

  final List<HeatmapData> heatmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGrid(context),
        const SizedBox(height: 12),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    // Group by week
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysInYear =
        DateTime(now.year, 12, 31).difference(startOfYear).inDays + 1;

    // Create map for quick lookup
    final heatmapMap = {for (var h in heatmap) h.date: h};

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: (daysInYear / 7).ceil(),
        itemBuilder: (context, weekIndex) {
          return Column(
            children: List.generate(7, (dayIndex) {
              final dayOffset = weekIndex * 7 + dayIndex;
              if (dayOffset >= daysInYear) {
                return const SizedBox(width: 12, height: 12);
              }

              final date = startOfYear.add(Duration(days: dayOffset));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final data = heatmapMap[dateStr];
              final intensity = data?.intensity ?? 0;

              return Padding(
                padding: const EdgeInsets.all(1),
                child: Tooltip(
                  message: data != null
                      ? '${DateFormat('dd/MM/yyyy').format(date)}\n${data.count} hoạt động'
                      : DateFormat('dd/MM/yyyy').format(date),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.colors.heatmap(intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ít', style: TextStyle(fontSize: AppTypography.caption)),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.colors.heatmap(index),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('Nhiều',
                style: TextStyle(fontSize: AppTypography.caption)),
          ],
        ),
      ),
    );
  }
}
