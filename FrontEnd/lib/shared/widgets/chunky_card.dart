import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Thẻ "nổi khối" kiểu Duolingo: một mép đặc ở đáy tạo cảm giác 3D; khi bấm,
/// mặt thẻ lún xuống đúng bằng bề dày mép, như đang nhấn xuống bệ của nó.
///
/// Hai dạng, suy ra từ [color]:
/// - **Trung tính** (không truyền `color`): nền bề mặt, viền mảnh, mép cùng
///   màu viền — thẻ đọc nội dung, ô lưới.
/// - **Tô màu** (truyền `color`): không viền, mép là sắc đậm hơn của chính màu
///   nền — thẻ hành động, chip chỉ số.
///
/// Mép luôn tính tự động, không truyền riêng, để mọi thẻ trong app cùng một
/// quy tắc.
class ChunkyCard extends StatefulWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = AppSpacing.card,
    this.borderRadius = AppRadius.xlAll,
    this.edgeHeight = edgeDepth,
  });

  /// Bề dày mép mặc định của mọi thẻ nổi khối.
  static const double edgeDepth = 4;

  /// Bề dày viền của thẻ trung tính.
  static const double borderWidth = 2;

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  /// Độ cao mép ở trạng thái nghỉ, cũng là khoảng lún xuống khi bấm.
  final double edgeHeight;

  /// Sắc đậm hơn của [color], dùng làm mép cho thẻ và ô tô màu.
  static Color edgeOf(Color color) => Color.lerp(color, Colors.black, 0.2)!;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutral = widget.color == null;
    final baseColor = widget.color ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    // Thẻ trung tính trên nền sáng: mép trùng màu viền cho ra nét "đồ chơi"
    // của mockup. Nền tối nuốt mép nhạt, nên ở đó mép phải thẫm hẳn xuống.
    final edgeColor = !neutral
        ? ChunkyCard.edgeOf(baseColor)
        : isDark
            ? Color.lerp(baseColor, Colors.black, 0.4)!
            : borderColor;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final pressed = _pressed;
    final tappable = widget.onTap != null;

    Widget card = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: Curves.easeOut,
      transform:
          Matrix4.translationValues(0, pressed ? widget.edgeHeight : 0, 0),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: widget.borderRadius,
        border: neutral
            ? Border.all(color: borderColor, width: ChunkyCard.borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: edgeColor,
            offset: Offset(0, pressed ? 0 : widget.edgeHeight),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (tappable) {
      card = Semantics(
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onTap,
            child: card,
          ),
        ),
      );
    }

    // Chừa chỗ cho mép bên dưới, để thẻ kế tiếp không đè lên nó.
    return Padding(
      padding: EdgeInsets.only(bottom: widget.edgeHeight),
      child: card,
    );
  }
}
