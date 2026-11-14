import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_table.dart';
import 'admin_content_format.dart';

/// Cột bảng nội dung trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
List<AdaptiveColumn<Map<String, dynamic>>> adminContentColumns(
  String type, {
  required void Function(String action, Map<String, dynamic> item) onAction,
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
        cell: (context, item) =>
            Text((item['meaning'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Cấp độ',
        width: 96,
        cell: (context, item) => Text((item['level'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, item) => PopupMenuButton<String>(
          onSelected: (action) => onAction(action, item),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa')),
            PopupMenuItem(value: 'delete', child: Text('Xoá')),
          ],
        ),
      ),
    ];
