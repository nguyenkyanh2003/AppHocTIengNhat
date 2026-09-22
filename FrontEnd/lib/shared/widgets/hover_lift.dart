import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Ô bấm được có hiệu ứng rê chuột cho bản web/desktop: nền đổi sang
/// [hoverColor], viền đậm lên và ô nhấc nhẹ lên trên.
///
/// Trên điện thoại không có trạng thái rê chuột nên ô chỉ còn hiệu ứng chạm
/// của [InkWell] — không cần tách hai bản.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.color,
    this.hoverColor,
    this.borderRadius = AppRadius.mdAll,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? hoverColor;
  final BorderRadius borderRadius;
  final String? tooltip;

  /// Độ nhấc khi rê chuột.
  static const double lift = 2;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interactive = widget.onTap != null;
    final hovered = interactive && _hovered;
    final base = widget.color ?? theme.colorScheme.surfaceContainerLowest;
    final hover = widget.hoverColor ?? AppColors.primaryLight;

    Widget tile = MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        transform:
            Matrix4.translationValues(0, hovered ? -HoverLift.lift : 0, 0),
        decoration: BoxDecoration(
          color: hovered ? hover : base,
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: hovered ? theme.colorScheme.primary : AppColors.border,
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: AppSpacing.md,
                    offset: const Offset(0, AppSpacing.xs),
                  ),
                ]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      tile = Tooltip(message: widget.tooltip!, child: tile);
    }
    return tile;
  }
}
