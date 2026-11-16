import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/network/api_envelope.dart';
import '../models/admin_content_type.dart';
import '../utils/admin_content_csv.dart';
import 'admin_content_format.dart';
import 'admin_content_table.dart';

/// Một mục nội dung ở khổ hẹp.
class AdminContentCard extends StatelessWidget {
  const AdminContentCard({super.key, required this.item, required this.type, required this.onAction});

  final JsonObject item;
  final AdminContentType type;
  final void Function(AdminContentAction action, JsonObject item) onAction;

  @override
  Widget build(BuildContext context) {
    final levelColor = AppTheme.getJlptLevelColor('${item['level'] ?? ''}');
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: levelColor.withValues(alpha: 0.18),
          child: Text(
            _badge,
            maxLines: 1,
            style: TextStyle(color: context.colors.readable(levelColor), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          adminContentTitle(type, item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: AdminContentMenu(item: item, onAction: onAction),
      ),
    );
  }

  /// Ký tự đầu của mặt chữ (bài học: số thứ tự).
  String get _badge {
    final value = switch (type) {
      AdminContentType.vocabulary => item['word'],
      AdminContentType.kanji => item['character'],
      AdminContentType.grammar => item['title'],
      AdminContentType.lessons => item['order'],
    };
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? '?' : text.characters.first;
  }

  String get _subtitle {
    final level = item['level'] ?? '';
    return switch (type) {
      AdminContentType.vocabulary => '${item['meaning'] ?? ''} • $level',
      AdminContentType.kanji =>
        'On: ${AdminContentCsv.displayValue(item['onyomi'])} • Kun: ${AdminContentCsv.displayValue(item['kunyomi'])} • $level',
      AdminContentType.grammar => '${item['structure'] ?? ''} • $level',
      AdminContentType.lessons => 'Bài ${item['order'] ?? ''} • $level • ${item['type'] ?? 'Chưa phân loại'}',
    };
  }
}
