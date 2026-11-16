import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Phân bố người dùng theo trình độ.
class AdminLevelDistribution extends StatelessWidget {
  const AdminLevelDistribution({super.key, required this.distribution});

  /// Số người theo trình độ.
  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phân bố trình độ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            if (distribution.isEmpty)
              const Text('Chưa có dữ liệu trình độ.')
            else
              for (final MapEntry(key: level, value: count) in distribution.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(width: 72, child: Text(level)),
                      Expanded(child: LinearProgressIndicator(value: total == 0 ? 0 : count / total)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('$count (${total == 0 ? 0 : (count * 100 / total).round()}%)'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
