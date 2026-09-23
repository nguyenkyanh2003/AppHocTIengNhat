import 'package:flutter/material.dart';

import 'srs_confirm_dialog.dart';

enum _CardAction { skip, reset, remove }

/// Menu thao tác trên thẻ đang ôn: bỏ qua, đặt lại lịch, xoá khỏi lịch ôn.
///
/// Đặt lại và xoá có hậu quả khác nhau nên đều hỏi lại, nói rõ hậu quả.
class SrsCardMenu extends StatelessWidget {
  const SrsCardMenu({
    super.key,
    required this.enabled,
    required this.onSkip,
    required this.onReset,
    required this.onRemove,
  });

  final bool enabled;
  final VoidCallback onSkip;
  final VoidCallback onReset;
  final VoidCallback onRemove;

  Future<void> _select(BuildContext context, _CardAction action) async {
    switch (action) {
      case _CardAction.skip:
        onSkip();
      case _CardAction.reset:
        if (await confirmSrsAction(
          context,
          title: 'Đặt lại lịch ôn?',
          message: 'Thẻ về hộp 1 và sẽ đến hạn lại sau 24 giờ. Từ vẫn được giữ là đã học.',
          confirmLabel: 'Đặt lại',
        )) {
          onReset();
        }
      case _CardAction.remove:
        if (context.mounted &&
            await confirmSrsAction(
              context,
              title: 'Xoá khỏi lịch ôn?',
              message: 'Tiến độ ôn của từ này bị xoá và từ trở về trạng thái chưa học.',
              confirmLabel: 'Xoá',
            )) {
          onRemove();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CardAction>(
      enabled: enabled,
      tooltip: 'Thao tác với thẻ',
      onSelected: (action) => _select(context, action),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _CardAction.skip, child: Text('Bỏ qua trong phiên này')),
        PopupMenuItem(value: _CardAction.reset, child: Text('Đặt lại lịch ôn')),
        PopupMenuItem(value: _CardAction.remove, child: Text('Xoá khỏi lịch ôn')),
      ],
    );
  }
}
