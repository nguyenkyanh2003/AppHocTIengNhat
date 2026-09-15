import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/lesson_level.dart';

/// Hàng chọn trình độ của màn Bài học: Mọi trình độ · N5 … N1.
///
/// Luôn hiện và chỉ chọn một, để đổi trình độ mất đúng một chạm. Trình độ trong
/// hồ sơ có biểu tượng riêng, để người học vẫn biết đâu là cấp của mình khi
/// đang xem cấp khác.
class LessonLevelBar extends StatelessWidget {
  const LessonLevelBar({
    super.key,
    required this.selectedLevel,
    required this.userLevel,
    required this.onChanged,
  });

  /// Cấp đang lọc; `null` là mọi trình độ.
  final String? selectedLevel;

  /// Trình độ trong hồ sơ đã chuẩn hoá; `null` khi hồ sơ chưa có.
  final String? userLevel;

  final ValueChanged<String?> onChanged;

  static const allLevelsLabel = 'Mọi trình độ';

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...kLessonLevels];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pageHorizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => AppGap.sm,
        itemBuilder: (context, index) {
          final level = options[index];
          final isUserLevel = level != null && level == userLevel;

          return ChoiceChip(
            avatar: isUserLevel ? const Icon(Icons.person, size: 16) : null,
            tooltip: isUserLevel ? 'Trình độ trong hồ sơ của bạn' : null,
            label: Text(level ?? allLevelsLabel),
            selected: level == selectedLevel,
            showCheckmark: false,
            // Bấm lại cấp đang chọn không làm gì: nạp lại y hệt chỉ làm màn nháy.
            onSelected: (_) {
              if (level != selectedLevel) onChanged(level);
            },
          );
        },
      ),
    );
  }
}
