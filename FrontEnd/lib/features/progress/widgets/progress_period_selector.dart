import 'package:flutter/material.dart';

import '../providers/progress_provider.dart';

/// Các kỳ server hỗ trợ, khớp `PERIOD_DAYS` của backend.
const progressPeriods = {'week': '7 ngày', 'month': '30 ngày', 'year': '1 năm'};

/// Đổi kỳ, lỗi thì báo bằng snack bar vì số liệu cũ vẫn còn trên màn.
Future<void> changeProgressPeriod(
  BuildContext context,
  ProgressProvider provider,
  String period,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = await provider.changePeriod(period);
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }
}

/// Hàng nút chọn kỳ thống kê.
class ProgressPeriodSelector extends StatelessWidget {
  const ProgressPeriodSelector({super.key, required this.provider});

  final ProgressProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: period, value: label)
            in progressPeriods.entries)
          ChoiceChip(
            label: Text(label),
            selected: provider.selectedPeriod == period,
            onSelected: (_) => changeProgressPeriod(context, provider, period),
          ),
      ],
    );
  }
}
