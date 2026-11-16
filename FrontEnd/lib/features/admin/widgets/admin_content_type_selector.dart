import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_content_type.dart';

/// Hàng chọn loại nội dung đang quản lý.
class AdminContentTypeSelector extends StatelessWidget {
  const AdminContentTypeSelector({super.key, required this.selected, required this.onSelect});

  final AdminContentType selected;
  final ValueChanged<AdminContentType> onSelect;

  static (IconData, Color) _style(AdminContentType type) => switch (type) {
        AdminContentType.vocabulary => (Icons.book, AppColors.primary),
        AdminContentType.kanji => (Icons.text_fields, Colors.purple),
        AdminContentType.grammar => (Icons.list, AppColors.warning),
        AdminContentType.lessons => (Icons.school, AppColors.success),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: context.colors.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final type in AdminContentType.values)
              if (_style(type) case (final icon, final color))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: selected == type ? context.colors.readable(color) : context.colors.textSecondary,
                    ),
                    label: Text(type.label),
                    selected: selected == type,
                    selectedColor: color.withValues(alpha: 0.18),
                    onSelected: (isSelected) {
                      if (isSelected) onSelect(type);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
