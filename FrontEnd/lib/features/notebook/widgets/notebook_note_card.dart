import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/notebook.dart';
import 'notebook_type_badge.dart';

/// Một ghi chú trong danh sách; chạm để mở chi tiết.
class NotebookNoteCard extends StatelessWidget {
  const NotebookNoteCard({super.key, required this.note});

  final Notebook note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push('/notebook/${note.id}'),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    NotebookTypeBadge(type: note.type),
                    Text(
                      _relativeDate(note.updatedAt),
                      style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                note.title,
                style: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                note.content,
                style: TextStyle(fontSize: AppTypography.bodySmall, color: context.colors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final tag in note.tags.take(3))
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: AppTypography.caption),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    return switch (days) {
      0 => 'Hôm nay',
      1 => 'Hôm qua',
      < 7 => '$days ngày trước',
      _ => '${date.day}/${date.month}/${date.year}',
    };
  }
}
