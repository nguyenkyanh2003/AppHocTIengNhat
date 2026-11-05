import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Màu giao diện theo chế độ sáng / tối, đọc bằng `context.colors`.
///
/// Màu trung tính trong [AppColors] là hằng số của chế độ sáng: dùng thẳng trong
/// widget thì chữ tối nằm trên nền tối. Widget đọc từ đây; widget nào gọi
/// `context.colors` cũng tự dựng lại khi người dùng đổi giao diện. Giá trị của
/// [light] đúng bằng [AppColors] nên chế độ sáng không đổi diện mạo.
///
/// Màu nền đặc có chữ trắng ([AppColors.primary], [AppColors.error] làm nền nút)
/// không đi qua đây: chúng giữ nguyên ở cả hai chế độ.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.error,
    required this.heatmapLevels,
  });

  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  /// Bốn mức của lịch hoạt động; đọc qua [heatmap].
  final List<Color> heatmapLevels;

  /// Màu thương hiệu dùng làm chữ, icon, viền trên nền trung tính.
  final Color primary;

  /// Chữ và icon đậm trên [primarySoft].
  final Color primaryStrong;

  /// Nền nhạt của mục đang chọn, nhãn, ô nhấn.
  final Color primarySoft;

  /// Chữ và icon báo lỗi trên nền trung tính.
  final Color error;

  static const light = AppThemeColors(
    isDark: false,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    primary: AppColors.primary,
    primaryStrong: AppColors.primaryDark,
    primarySoft: AppColors.primaryLight,
    error: AppColors.error,
    heatmapLevels: AppColors.heatmapLight,
  );

  static const dark = AppThemeColors(
    isDark: true,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textDisabled: AppColors.darkTextDisabled,
    primary: AppColors.darkPrimary,
    primaryStrong: AppColors.darkPrimaryStrong,
    primarySoft: AppColors.darkPrimarySoft,
    error: AppColors.darkError,
    heatmapLevels: AppColors.heatmapDark,
  );

  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>() ?? light;

  /// Màu nhận diện (tím bài tập, hồng bài học...) khi dùng làm chữ hoặc icon trên
  /// nền trung tính: chế độ sáng đậm dần về màu chữ, chế độ tối sáng dần về màu
  /// trắng, tới khi đạt 4,5:1 trên cả thẻ lẫn ô nhập liệu. Màu đã đủ tương phản thì
  /// giữ nguyên nên không mất sắc nhận diện.
  ///
  /// Chữ nằm trên nền nhạt thì truyền nền đó vào [on] để tính đúng tương phản.
  Color readable(Color hue, {Color? on}) {
    final target = isDark ? Colors.white : textPrimary;
    var color = hue;
    for (var step = 1; step <= 10 && !_isReadable(color, on); step++) {
      color = Color.lerp(hue, target, step / 10)!;
    }
    return color;
  }

  /// Màu một ô lịch hoạt động: 0 là ô trống, 1–4 là ít tới nhiều.
  Color heatmap(int intensity) => intensity <= 0
      ? surfaceVariant
      : heatmapLevels[intensity.clamp(1, heatmapLevels.length) - 1];

  bool _isReadable(Color color, Color? on) =>
      _contrast(color, surface) >= 4.5 &&
      _contrast(color, surfaceVariant) >= 4.5 &&
      (on == null || _contrast(color, on) >= 4.5);

  static double _contrast(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    return first > second
        ? (first + 0.05) / (second + 0.05)
        : (second + 0.05) / (first + 0.05);
  }

  @override
  AppThemeColors copyWith() => this;

  /// Chỉ có hai bộ màu cố định, không cần nội suy từng màu khi đổi chế độ.
  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get colors => AppThemeColors.of(this);
}
