import 'package:flutter/material.dart';
import '../utils/admin_content_csv.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_theme.dart';

/// Một mục nội dung ở khổ hẹp.
class AdminContentCard extends StatelessWidget {
  const AdminContentCard({
    super.key,
    required this.item,
    required this.selectedContentType,
    required this.handleAction,
    required this.contentTitle,
  });

  final Map<String, dynamic> item;
  final String selectedContentType;
  final void Function(String action, Map<String, dynamic> item) handleAction;
  final String Function(Map<String, dynamic> item) contentTitle;

  @override
  Widget build(BuildContext context) {
    final levelColor =
        AppTheme.getJlptLevelColor(item['level']?.toString() ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: levelColor.withValues(alpha: 0.18),
          child: Text(
            _contentLabel(item),
            maxLines: 1,
            style: TextStyle(
              color: context.colors.readable(levelColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contentTitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _contentSubtitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => handleAction(action, item),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.copy),
                title: Text('Nhân bản'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete, color: context.colors.error),
                title:
                    Text('Xóa', style: TextStyle(color: context.colors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contentLabel(Map<String, dynamic> item) {
    final value = switch (selectedContentType) {
      'vocabulary' => item['word'],
      'kanji' => item['character'],
      'grammar' => item['title'],
      'lessons' => item['order'],
      _ => '?',
    };
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '?' : text.characters.first;
  }

  String _contentSubtitle(Map<String, dynamic> item) =>
      switch (selectedContentType) {
        'vocabulary' => '${item['meaning'] ?? ''} • ${item['level'] ?? ''}',
        'kanji' =>
          'On: ${AdminContentCsv.displayValue(item['onyomi'])} • Kun: ${AdminContentCsv.displayValue(item['kunyomi'])} • ${item['level'] ?? ''}',
        'grammar' => '${item['structure'] ?? ''} • ${item['level'] ?? ''}',
        'lessons' =>
          'Bài ${item['order'] ?? ''} • ${item['level'] ?? ''} • ${item['type'] ?? 'Chưa phân loại'}',
        _ => '',
      };
}
