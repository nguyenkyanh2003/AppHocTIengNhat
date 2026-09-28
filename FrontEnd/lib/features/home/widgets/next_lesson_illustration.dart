import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/calm_colors.dart';

/// Núi Phú Sĩ và mặt trời, vẽ bằng code trên nền trong suốt — hoà vào thẻ xanh
/// thay vì một ảnh nền trắng đặt lên trên, và nét luôn sắc ở mọi mật độ điểm
/// ảnh. Chỉ để trang trí nên ẩn khỏi trình đọc màn hình.
class NextLessonIllustration extends StatelessWidget {
  const NextLessonIllustration({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MountainPainter(sun: CalmColors.of(context).warm),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter({required this.sun});

  final Color sun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
        Offset(w * 0.72, h * 0.28), w * 0.15, Paint()..color = sun);

    final mountain = Path()
      ..moveTo(w * 0.02, h * 0.92)
      ..lineTo(w * 0.40, h * 0.36)
      ..quadraticBezierTo(w * 0.46, h * 0.30, w * 0.52, h * 0.36)
      ..lineTo(w * 0.98, h * 0.92)
      ..close();
    canvas.drawPath(mountain, Paint()..color = AppPalette.illustrationMountain);

    final snow = Path()
      ..moveTo(w * 0.31, h * 0.49)
      ..lineTo(w * 0.40, h * 0.36)
      ..quadraticBezierTo(w * 0.46, h * 0.30, w * 0.52, h * 0.36)
      ..lineTo(w * 0.62, h * 0.49)
      ..lineTo(w * 0.55, h * 0.45)
      ..lineTo(w * 0.49, h * 0.51)
      ..lineTo(w * 0.43, h * 0.45)
      ..lineTo(w * 0.37, h * 0.51)
      ..close();
    canvas.drawPath(snow, Paint()..color = AppPalette.illustrationSnow);

    final hill = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.22, h * 0.66, w * 0.46, h * 0.92)
      ..close();
    canvas.drawPath(hill, Paint()..color = AppPalette.illustrationHill);
  }

  @override
  bool shouldRepaint(_MountainPainter oldDelegate) => oldDelegate.sun != sun;
}
