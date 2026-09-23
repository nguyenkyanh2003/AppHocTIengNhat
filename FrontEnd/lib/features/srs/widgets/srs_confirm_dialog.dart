import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dialog.dart';

/// Hộp xác nhận dùng chung cho các thao tác SRS có hậu quả.
Future<bool> confirmSrsAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Huỷ')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return confirmed ?? false;
}
