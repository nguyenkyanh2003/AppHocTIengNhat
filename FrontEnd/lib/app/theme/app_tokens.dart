import 'package:flutter/material.dart';

/// Design token của ứng dụng.
///
/// Mọi màu, khoảng cách, bo góc và thời lượng animation đều lấy từ đây. Screen
/// và widget không tự đặt `Color(0x...)`, `EdgeInsets.all(17)` hay `Duration`
/// rời rạc — nếu thiếu giá trị nào thì bổ sung token mới ở file này.
abstract final class AppColors {
  // Thương hiệu
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFFFF9800);
  static const Color accent = Color(0xFF4CAF50);

  // Ngữ nghĩa
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF00BCD4);

  // Bề mặt - chế độ sáng
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);

  // Chữ - chế độ sáng
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Bề mặt - chế độ tối
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Chữ - chế độ tối
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextDisabled = Color(0xFF6E6E6E);

  // Màu nhận diện từng mảng nội dung
  static const Color vocabulary = Color(0xFF2196F3);
  static const Color grammar = Color(0xFF4CAF50);
  static const Color kanji = Color(0xFFFF9800);
  static const Color lesson = Color(0xFFE91E63);
  static const Color exercise = Color(0xFF9C27B0);
  static const Color jlpt = Color(0xFF673AB7);
  static const Color notebook = Color(0xFFFFC107);
  static const Color news = Color(0xFF00BCD4);
  static const Color group = Color(0xFF009688);
  static const Color progress = Color(0xFF8BC34A);

  /// Màu cấp độ JLPT, từ dễ (N5) đến khó (N1).
  static const Map<String, Color> jlptLevels = {
    'N5': Color(0xFF4CAF50),
    'N4': Color(0xFF8BC34A),
    'N3': Color(0xFFFFC107),
    'N2': Color(0xFFFF9800),
    'N1': Color(0xFFF44336),
  };
}

/// Thang khoảng cách 4pt. Chỉ dùng các bậc này, không chèn giá trị lẻ.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Padding chuẩn của một trang nội dung.
  static const EdgeInsets page = EdgeInsets.all(lg);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Khoảng trống dựng sẵn, thay cho `SizedBox(height: 17)` rải rác.
abstract final class AppGap {
  static const Widget xs = SizedBox(height: AppSpacing.xs, width: AppSpacing.xs);
  static const Widget sm = SizedBox(height: AppSpacing.sm, width: AppSpacing.sm);
  static const Widget md = SizedBox(height: AppSpacing.md, width: AppSpacing.md);
  static const Widget lg = SizedBox(height: AppSpacing.lg, width: AppSpacing.lg);
  static const Widget xl = SizedBox(height: AppSpacing.xl, width: AppSpacing.xl);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppElevation {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
