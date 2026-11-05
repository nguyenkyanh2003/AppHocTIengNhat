import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notebook.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Một ghi chú trong danh sách.
class NotebookNoteCard extends StatelessWidget {
  const NotebookNoteCard({
    super.key,
    required this.note,
    required this.getTypeLabel,
  });

  final Notebook note;
  final String Function(String type) getTypeLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(context, note.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(note.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        getTypeLabel(note.type),
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color:
                              context.colors.readable(_getTypeColor(note.type)),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(note.updatedAt),
                      style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: context.colors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: note.tags.take(3).map<Widget>((tag) {
                    return Chip(
                      label: Text(tag.toString()),
                      visualDensity: VisualDensity.compact,
                      labelStyle:
                          const TextStyle(fontSize: AppTypography.caption),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String noteId) {
    context.push('/notebook/$noteId');
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vocabulary':
        return AppTheme.vocabularyColor;
      case 'grammar':
        return AppTheme.grammarColor;
      case 'kanji':
        return AppTheme.kanjiColor;
      default:
        return AppTheme.notebookColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
