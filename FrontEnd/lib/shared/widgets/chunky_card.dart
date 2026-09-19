import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Thẻ "nổi khối" kiểu Duolingo: một mép đặc màu đậm hơn ở đáy tạo cảm giác
/// 3D; khi bấm, mặt thẻ dịch xuống và mép co lại như đang nhấn xuống bệ của
/// nó.
///
/// [color] mặc định lấy `colorScheme.surface` của theme hiện tại (đọc tốt ở
/// cả sáng/tối); truyền `color` để có thẻ tô màu mảng. Mép luôn tính tự động
/// từ [color], không truyền riêng.
class ChunkyCard extends StatefulWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = AppSpacing.card,
    this.borderRadius = AppRadius.xlAll,
    this.edgeHeight = 4,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  /// Độ cao mép ở trạng thái nghỉ, cũng là khoảng cách dịch xuống khi bấm.
  final double edgeHeight;

  @override
  State<ChunkyCard> createState() => _ChunkyCardState();
}

class _ChunkyCardState extends State<ChunkyCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.color ?? theme.colorScheme.surface;
    // Nền tối nuốt mép thẫm, nên phải hạ sâu hơn hẳn so với nền sáng thì khối
    // mới nổi lên.
    final edgeColor = Color.lerp(
      baseColor,
      Colors.black,
      theme.brightness == Brightness.dark ? 0.4 : 0.22,
    )!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final pressed = _pressed;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.edgeHeight),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppDurations.fast,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
              0, pressed ? widget.edgeHeight : 0, 0),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: edgeColor,
                offset: Offset(0, pressed ? 0 : widget.edgeHeight),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
