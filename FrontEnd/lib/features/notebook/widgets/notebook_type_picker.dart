import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/notebook.dart';
import 'notebook_type_badge.dart';

/// Chọn loại ghi chú; mỗi loại một màu, giống màu của mục học tương ứng.
class NotebookTypePicker extends StatelessWidget {
  const NotebookTypePicker({super.key, required this.selected, required this.onSelected});

  final NoteType selected;
  final ValueChanged<NoteType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại ghi chú',
          style: TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final type in NoteType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: selected == type,
                onSelected: (picked) {
                  if (picked) onSelected(type);
                },
                selectedColor: type.color,
                labelStyle: TextStyle(color: selected == type ? Colors.white : null),
              ),
          ],
        ),
      ],
    );
  }
}
