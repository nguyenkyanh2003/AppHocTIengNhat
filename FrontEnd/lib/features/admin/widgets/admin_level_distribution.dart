import 'package:flutter/material.dart';

/// Phân bố người dùng theo trình độ.
class AdminLevelDistribution extends StatelessWidget {
  const AdminLevelDistribution({
    super.key,
    required this.rawDistribution,
  });

  final dynamic rawDistribution;

  @override
  Widget build(BuildContext context) {
    final distribution = rawDistribution is Map
        ? Map<String, dynamic>.from(rawDistribution)
        : <String, dynamic>{};
    final total = distribution.values.fold<num>(
      0,
      (sum, value) => sum + ((value as num?) ?? 0),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bố trình độ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (distribution.isEmpty)
              const Text('Chưa có dữ liệu trình độ.')
            else
              ...distribution.entries.map((entry) {
                final count = (entry.value as num?) ?? 0;
                final ratio = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text(entry.key)),
                      Expanded(child: LinearProgressIndicator(value: ratio)),
                      const SizedBox(width: 10),
                      Text('${count.round()} (${(ratio * 100).round()}%)'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
