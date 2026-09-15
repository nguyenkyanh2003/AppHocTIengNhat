import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/situation_labels.dart';

/// Dải chip chọn chủ đề (đi siêu thị, đi tàu...) của trình độ đang lọc.
///
/// Ẩn hẳn khi chưa có chủ đề nào để không chiếm chỗ bằng một thanh trống.
class LessonSituationBar extends StatelessWidget {
  const LessonSituationBar({
    super.key,
    required this.situations,
    required this.selectedSituation,
    required this.onChanged,
  });

  final List<String> situations;

  /// Chủ đề đang lọc; `null` là mọi chủ đề.
  final String? selectedSituation;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (situations.isEmpty) return const SizedBox.shrink();

    final options = <String?>[null, ...situations];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pageHorizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => AppGap.sm,
        itemBuilder: (context, index) {
          final code = options[index];

          return FilterChip(
            avatar: Icon(
              code == null ? Icons.apps : situationIcon(code),
              size: 18,
            ),
            label: Text(code == null ? 'Mọi chủ đề' : situationLabel(code)),
            selected: code == selectedSituation,
            onSelected: (_) {
              if (code != selectedSituation) onChanged(code);
            },
          );
        },
      ),
    );
  }
}
