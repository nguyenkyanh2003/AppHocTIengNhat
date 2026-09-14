import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Thang chữ dùng chung cho cả chế độ sáng và tối.
///
/// Chỉ có một định nghĩa duy nhất: chế độ tối chỉ đổi màu chữ, không đổi cỡ hay
/// độ đậm.
///
/// Bảy bậc, nền 16px. Trước đây codebase dùng 20 cỡ khác nhau (9, 11, 13, 15,
/// 17, 22, 36, 42...) và cỡ phổ biến nhất là 12px — chữ cạnh nhau lệch 1-2px
/// đọc ra như lỗi chứ không ra nhịp, và 12px thì quá nhỏ cho một app học ngoại
/// ngữ. Muốn thêm bậc mới thì sửa ở đây, không đặt `fontSize` rời trong màn hình.
abstract final class AppTypography {
  static const double display = 32;
  static const double headline = 24;
  static const double title = 20;
  static const double subtitle = 18;
  static const double body = 16;
  static const double bodySmall = 14;
  static const double caption = 12;

  /// Inter cho chữ Latin: dấu tiếng Việt đầy đủ và rõ ở cỡ nhỏ.
  static TextStyle _latin({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) =>
      TextTheme(
        // Số liệu lớn, màn chào
        displayLarge: _latin(
            size: display,
            weight: FontWeight.w700,
            color: primary,
            height: 1.2,
            letterSpacing: -0.5),
        displayMedium: _latin(
            size: headline,
            weight: FontWeight.w700,
            color: primary,
            height: 1.25,
            letterSpacing: -0.3),
        displaySmall: _latin(
            size: title, weight: FontWeight.w700, color: primary, height: 1.3),

        // Tiêu đề màn và khối
        headlineLarge: _latin(
            size: headline,
            weight: FontWeight.w700,
            color: primary,
            height: 1.25),
        headlineMedium: _latin(
            size: title, weight: FontWeight.w600, color: primary, height: 1.3),
        headlineSmall: _latin(
            size: subtitle,
            weight: FontWeight.w600,
            color: primary,
            height: 1.35),

        // Tiêu đề thẻ
        titleLarge: _latin(
            size: title, weight: FontWeight.w600, color: primary, height: 1.3),
        titleMedium: _latin(
            size: subtitle,
            weight: FontWeight.w600,
            color: primary,
            height: 1.35),
        titleSmall: _latin(
            size: body, weight: FontWeight.w600, color: primary, height: 1.4),

        // Nội dung
        bodyLarge: _latin(
            size: body, weight: FontWeight.w400, color: primary, height: 1.5),
        bodyMedium: _latin(
            size: bodySmall,
            weight: FontWeight.w400,
            color: primary,
            height: 1.5),
        bodySmall: _latin(
            size: caption,
            weight: FontWeight.w400,
            color: secondary,
            height: 1.45),

        // Nhãn, nút, metadata
        labelLarge: _latin(
            size: bodySmall, weight: FontWeight.w600, color: primary),
        labelMedium:
            _latin(size: caption, weight: FontWeight.w500, color: secondary),
        labelSmall:
            _latin(size: caption, weight: FontWeight.w500, color: secondary),
      );

  /// Chữ Nhật là nội dung chính của app, không phải trang trí: kanji cần cỡ lớn
  /// và dòng thoáng thì mới đọc được nét. Noto Sans JP phủ đủ kanji/kana mà
  /// Inter không có.
  static TextStyle japaneseDisplay({Color? color}) => GoogleFonts.notoSansJp(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  /// Câu tiếng Nhật trong hội thoại, ví dụ, đề bài.
  static TextStyle japaneseBody({Color? color}) => GoogleFonts.notoSansJp(
        fontSize: subtitle,
        fontWeight: FontWeight.w500,
        height: 1.7,
        color: color,
      );

  /// Cách đọc (hiragana) đi kèm chữ Nhật — nhỏ và nhạt hơn câu chính.
  static TextStyle japaneseReading({Color? color}) => GoogleFonts.notoSansJp(
        fontSize: bodySmall,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? AppColors.textSecondary,
      );
}
