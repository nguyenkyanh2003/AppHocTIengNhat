import 'package:flutter/material.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Biểu đồ một chỉ số theo ngày.
class AdminAnalyticsChart extends StatelessWidget {
  const AdminAnalyticsChart({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.labels,
    required this.values,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> labels;
  final List<num> values;

  @override
  Widget build(BuildContext context) {
    final count = values.length < labels.length ? values.length : labels.length;
    final maxValue = values.isEmpty
        ? 1.0
        : values
            .fold<num>(0, (max, value) => value > max ? value : max)
            .toDouble();
    final labelHeight =
        MediaQuery.textScalerOf(context).scale(AppTypography.caption) * 1.4;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.readable(color)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (count == 0)
              const SizedBox(
                height: 80,
                child:
                    Center(child: Text('Chưa có dữ liệu trong giai đoạn này.')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: SizedBox(
                  width: count * 46.0,
                  height: 8 + 95 + 8 + labelHeight * 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(count, (index) {
                      final normalized =
                          maxValue == 0 ? 0.0 : values[index] / maxValue;
                      return SizedBox(
                        width: 46,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: labelHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${values[index].round()}',
                                    style: const TextStyle(
                                        fontSize: AppTypography.caption)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 8 + normalized * 95,
                              decoration: BoxDecoration(
                                color: context.colors
                                    .readable(color)
                                    .withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: labelHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _shortDate(labels[index]),
                                  style: const TextStyle(
                                      fontSize: AppTypography.caption),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : '${date.day}/${date.month}';
  }
}
