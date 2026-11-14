import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/export_document.dart';

/// Tên, mô tả và biểu tượng của từng nhóm dữ liệu xuất được.
const exportTypeOptions = <String, (String, String, IconData)>{
  ExportType.fullStats: ('Thống kê tổng quan', 'Tiến độ, phân tích bài học và streak', Icons.analytics_outlined),
  ExportType.lessonProgress: ('Tiến độ bài học', 'Toàn bộ tiến độ học tập hiện có', Icons.trending_up),
  ExportType.notebook: ('Ghi chép', 'Danh sách ghi chú cá nhân', Icons.note_alt_outlined),
  ExportType.achievements: ('Thành tích', 'Thành tích đã mở khóa và đang thực hiện', Icons.emoji_events_outlined),
  ExportType.streaks: (
    'Streak và XP',
    'Chuỗi học tập, toàn bộ lịch sử điểm và lịch ngày học',
    Icons.local_fire_department_outlined,
  ),
  ExportType.allData: ('Toàn bộ dữ liệu', 'Gộp tất cả nhóm dữ liệu phía trên', Icons.archive_outlined),
};

/// Đầu trang xuất dữ liệu.
class ExportHeader extends StatelessWidget {
  const ExportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          Icon(Icons.download, size: 52, color: context.colors.primary),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Sao lưu dữ liệu học tập',
            style: TextStyle(fontSize: AppTypography.title, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('Dữ liệu được lấy trực tiếp từ tài khoản tại thời điểm xuất.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Danh sách chọn một nhóm dữ liệu; [onChanged] `null` khi đang xuất.
class ExportTypePicker extends StatelessWidget {
  const ExportTypePicker({super.key, required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Column(
      children: [
        for (final MapEntry(key: type, value: (title, subtitle, icon)) in exportTypeOptions.entries)
          Card(
            child: RadioListTile<String>(
              value: type,
              groupValue: selected,
              onChanged: onChanged == null ? null : (value) => onChanged(value!),
              secondary: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
            ),
          ),
      ],
    );
  }
}

/// Chọn JSON hay CSV; [onChanged] `null` khi đang xuất.
class ExportFormatPicker extends StatelessWidget {
  const ExportFormatPicker({super.key, required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: ExportFormat.json, icon: Icon(Icons.data_object), label: Text('JSON')),
        ButtonSegment(value: ExportFormat.csv, icon: Icon(Icons.table_view), label: Text('CSV')),
      ],
      selected: {selected},
      onSelectionChanged: onChanged == null ? null : (values) => onChanged(values.single),
    );
  }
}
