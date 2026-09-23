import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../providers/srs_provider.dart';

/// Số từ vựng đến hạn ôn, cho mục "Ôn tập hôm nay" ở trang hub.
///
/// Tự làm mới mỗi lần hiện ra (vào hub), không đặt số liệu động vào metadata
/// điều hướng — số liệu nằm ở [SrsProvider].
class SrsDueBadge extends StatefulWidget {
  const SrsDueBadge({super.key});

  /// Dùng làm `AppNavEntry.trailing`: một tear-off tĩnh nên khai báo được `const`.
  static Widget builder(BuildContext context) => const SrsDueBadge();

  @override
  State<SrsDueBadge> createState() => _SrsDueBadgeState();
}

class _SrsDueBadgeState extends State<SrsDueBadge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SrsProvider>().loadDueCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<SrsProvider>().dueCount ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.streak,
    );
  }
}
