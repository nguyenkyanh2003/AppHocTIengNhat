import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Thang chữ dùng chung cho cả chế độ sáng và tối.
///
/// Chỉ có một định nghĩa duy nhất: chế độ tối chỉ đổi màu chữ, không đổi cỡ hay
/// độ đậm. Trước đây dark theme khai báo lại 4 style nên phần lớn chữ trong chế
/// độ tối rơi về mặc định của Material và lệch hẳn với chế độ sáng.
abstract final class AppTypography {
  static const double display = 32;
  static const double title = 20;
  static const double body = 14;
  static const double caption = 12;

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) =>
      TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: primary),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: primary),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: primary),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: primary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.normal, color: primary),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.normal, color: secondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
        labelSmall: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: secondary),
      );

  /// Chữ tiếng Nhật cỡ lớn (từ vựng, kanji) — cần dòng thoáng hơn chữ Latin.
  static const TextStyle japaneseDisplay = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle japaneseReading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
