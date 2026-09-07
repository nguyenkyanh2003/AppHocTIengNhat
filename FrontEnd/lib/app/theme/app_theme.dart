import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'app_typography.dart';

/// Theme của ứng dụng, lắp từ token trong [AppColors], [AppSpacing], [AppRadius]
/// và thang chữ trong [AppTypography].
///
/// Các hằng số màu ở đây là alias giữ lại cho code cũ; code mới dùng thẳng
/// `AppColors` hoặc `Theme.of(context)`.
class AppTheme {
  // Màu sắc chính
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accentColor = AppColors.accent;
  static const Color errorColor = AppColors.error;
  static const Color warningColor = AppColors.warning;

  // Màu nền
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color cardColor = AppColors.surface;

  // Màu chữ
  static const Color textPrimaryColor = AppColors.textPrimary;
  static const Color textSecondaryColor = AppColors.textSecondary;
  static const Color textDisabledColor = AppColors.textDisabled;

  // Màu cho từng tính năng
  static const Color vocabularyColor = AppColors.vocabulary;
  static const Color grammarColor = AppColors.grammar;
  static const Color kanjiColor = AppColors.kanji;
  static const Color lessonColor = AppColors.lesson;
  static const Color exerciseColor = AppColors.exercise;
  static const Color jlptColor = AppColors.jlpt;
  static const Color notebookColor = AppColors.notebook;
  static const Color newsColor = AppColors.news;
  static const Color groupColor = AppColors.group;
  static const Color progressColor = AppColors.progress;

  // Màu cấp độ JLPT
  static const Map<String, Color> jlptLevelColors = AppColors.jlptLevels;

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceVariant: AppColors.surfaceVariant,
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        appBarBackground: AppColors.primary,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        border: AppColors.darkBorder,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        appBarBackground: AppColors.darkSurface,
      );

  /// Một định nghĩa duy nhất cho cả hai chế độ: chỉ bảng màu đổi, còn cỡ chữ,
  /// bo góc và khoảng cách giữ nguyên để hai chế độ không lệch nhau.
  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color appBarBackground,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: surface,
        brightness: brightness,
      ),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      textTheme: AppTypography.textTheme(
        primary: textPrimary,
        secondary: textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: Colors.white,
        elevation: AppElevation.none,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: AppTypography.title,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: AppElevation.low,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppElevation.low,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(fontSize: 14, color: textSecondary),
        floatingLabelStyle:
            const TextStyle(fontSize: 16, color: AppColors.primary),
        hintStyle: TextStyle(fontSize: 14, color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.high,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.medium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        disabledColor: border,
        labelStyle:
            TextStyle(fontSize: AppTypography.caption, color: textPrimary),
        secondaryLabelStyle: const TextStyle(
          fontSize: AppTypography.caption,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        elevation: AppElevation.high,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: TextStyle(
          fontSize: AppTypography.title,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: textSecondary),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textPrimary, size: 24),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        minLeadingWidth: 40,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Lấy màu theo tên tính năng
  static Color getFeatureColor(String feature) {
    switch (feature.toLowerCase()) {
      case 'vocabulary':
        return AppColors.vocabulary;
      case 'grammar':
        return AppColors.grammar;
      case 'kanji':
        return AppColors.kanji;
      case 'lesson':
        return AppColors.lesson;
      case 'exercise':
        return AppColors.exercise;
      case 'jlpt':
        return AppColors.jlpt;
      case 'notebook':
        return AppColors.notebook;
      case 'news':
        return AppColors.news;
      case 'group':
        return AppColors.group;
      case 'progress':
        return AppColors.progress;
      default:
        return AppColors.primary;
    }
  }

  /// Lấy màu theo cấp độ JLPT
  static Color getJlptLevelColor(String level) =>
      AppColors.jlptLevels[level.toUpperCase()] ?? AppColors.primary;
}
