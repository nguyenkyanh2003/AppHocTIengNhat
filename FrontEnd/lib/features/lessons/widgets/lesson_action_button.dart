import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/chunky_card.dart';

/// Nút hành động chính của luồng học — khối xanh lá như thẻ "Học tiếp" ở
/// trang chủ, để mọi lời mời "làm bước tiếp theo" trong app nhìn giống nhau.
///
/// `onPressed == null` là trạng thái chưa bấm được (ví dụ chưa trả lời hết câu
/// kiểm tra): khối chuyển xám và không lún khi chạm.
class LessonActionButton extends StatelessWidget {
  const LessonActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    const foreground = Colors.white;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ChunkyCard(
        color: enabled ? AppColors.heroAction : AppColors.textDisabled,
        borderRadius: AppRadius.lgAll,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
        onTap: enabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
              )
            else if (icon != null)
              Icon(icon, color: foreground),
            if (busy || icon != null) AppGap.sm,
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.heroDisplay(size: AppTypography.subtitle, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
