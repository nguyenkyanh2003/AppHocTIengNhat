import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Hàng chọn loại nội dung đang quản lý.
class AdminContentTypeSelector extends StatelessWidget {
  const AdminContentTypeSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  static const _types = [
    ('Từ vựng', 'vocabulary', Icons.book, AppColors.primary),
    ('Kanji', 'kanji', Icons.text_fields, Colors.purple),
    ('Ngữ pháp', 'grammar', Icons.list, AppColors.warning),
    ('Bài học', 'lessons', Icons.school, AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: context.colors.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (label, value, icon, color) in _types)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 16,
                    color: selected == value
                        ? context.colors.readable(color)
                        : context.colors.textSecondary,
                  ),
                  label: Text(label),
                  selected: selected == value,
                  selectedColor: color.withValues(alpha: 0.18),
                  onSelected: (isSelected) {
                    if (isSelected) onSelect(value);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
