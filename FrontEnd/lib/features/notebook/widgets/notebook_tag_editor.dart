import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';

/// Nhập và gỡ các thẻ của một ghi chú.
class NotebookTagEditor extends StatelessWidget {
  const NotebookTagEditor({
    super.key,
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thẻ',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập thẻ...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: onAdd,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Thêm thẻ',
              onPressed: () => onAdd(controller.text),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(tag),
                  onDeleted: () => onRemove(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
      ],
    );
  }
}
