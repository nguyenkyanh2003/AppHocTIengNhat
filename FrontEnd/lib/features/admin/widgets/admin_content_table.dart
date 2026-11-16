import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/network/api_envelope.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../models/admin_content_type.dart';
import 'admin_content_format.dart';

/// Thao tác trên một mục nội dung.
enum AdminContentAction {
  edit('Chỉnh sửa', Icons.edit),
  duplicate('Nhân bản', Icons.copy),
  delete('Xoá', Icons.delete);

  const AdminContentAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Menu thao tác của một mục, dùng chung cho thẻ và bảng.
class AdminContentMenu extends StatelessWidget {
  const AdminContentMenu({super.key, required this.item, required this.onAction});

  final JsonObject item;
  final void Function(AdminContentAction action, JsonObject item) onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AdminContentAction>(
      tooltip: 'Thao tác',
      onSelected: (action) => onAction(action, item),
      itemBuilder: (context) => [
        for (final action in AdminContentAction.values)
          PopupMenuItem(
            value: action,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(action.icon, color: action == AdminContentAction.delete ? context.colors.error : null),
              title: Text(
                action.label,
                style: TextStyle(color: action == AdminContentAction.delete ? context.colors.error : null),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cột bảng nội dung trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
List<AdaptiveColumn<JsonObject>> adminContentColumns(
  AdminContentType type, {
  required void Function(AdminContentAction action, JsonObject item) onAction,
}) =>
    [
      AdaptiveColumn(
        label: 'Nội dung',
        minWidth: 220,
        cell: (context, item) =>
            Text(adminContentHeadline(type, item), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Nghĩa',
        minWidth: 200,
        cell: (context, item) => Text('${item['meaning'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Cấp độ',
        width: 96,
        cell: (context, item) => Text('${item['level'] ?? ''}'),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, item) => AdminContentMenu(item: item, onAction: onAction),
      ),
    ];
