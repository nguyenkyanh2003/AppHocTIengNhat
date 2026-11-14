import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Nhãn đậm trên mỗi ô của form báo cáo.
class ReportFieldLabel extends StatelessWidget {
  const ReportFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTypography.body)),
    );
  }
}

/// Ba mức ưu tiên của báo cáo, chọn một.
class ReportPriorityPicker extends StatelessWidget {
  const ReportPriorityPicker({super.key, required this.selected, required this.onSelected});

  static const priorities = {'low': '🟢 Thấp', 'medium': '🟡 Trung bình', 'high': '🔴 Cao'};

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, MapEntry(key: value, value: label)) in priorities.entries.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelected(value),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected == value ? AppColors.primary : context.colors.border,
                foregroundColor: selected == value ? Colors.white : context.colors.textPrimary,
              ),
              child: Text(label),
            ),
          ),
        ],
      ],
    );
  }
}

/// Lỗi gửi báo cáo, hiện ngay dưới nút gửi.
class ReportErrorBox extends StatelessWidget {
  const ReportErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: context.colors.error),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(message, style: TextStyle(color: context.colors.error)),
    );
  }
}
