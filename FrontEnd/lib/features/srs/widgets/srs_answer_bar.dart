import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Nút thao tác dưới thẻ ôn, theo đúng thứ tự của một lượt: lật thẻ trước,
/// rồi mới tự đánh giá "Nhớ" / "Chưa nhớ".
///
/// Thẻ mất nội dung không trả lời được — chỉ còn bỏ qua hoặc xoá. Mọi nút tắt
/// khi đang gửi, để bấm đôi không thành hai lượt.
class SrsAnswerBar extends StatelessWidget {
  const SrsAnswerBar({
    super.key,
    required this.revealed,
    required this.unavailable,
    required this.busy,
    required this.onReveal,
    required this.onAnswer,
    required this.onSkip,
    required this.onRemove,
  });

  final bool revealed;
  final bool unavailable;
  final bool busy;
  final VoidCallback onReveal;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onSkip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (unavailable) {
      return _Pair(
        left: OutlinedButton.icon(
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next),
          label: const Text('Bỏ qua'),
        ),
        right: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xoá khỏi lịch ôn'),
        ),
      );
    }

    if (!revealed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.flip),
            label: const Text('Lật thẻ'),
          ),
          AppGap.sm,
          TextButton(onPressed: onSkip, child: const Text('Bỏ qua trong phiên này')),
        ],
      );
    }

    return _Pair(
      left: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: () => onAnswer(false),
        icon: const Icon(Icons.close),
        label: const Text('Chưa nhớ'),
      ),
      right: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        onPressed: () => onAnswer(true),
        icon: const Icon(Icons.check),
        label: const Text('Nhớ'),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        AppGap.md,
        Expanded(child: right),
      ],
    );
  }
}
