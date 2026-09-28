import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tông màu của từng ô ở "Góc học tập" trên Trang chủ.
enum StudyCornerTone { lesson, vocabulary, kanji, exercise, jlpt, group, notebook }

/// Bảng màu dịu (xem [AppPalette]) theo chế độ sáng / tối.
///
/// Đăng ký trong `ThemeData.extensions`, đọc bằng [CalmColors.of]. Chế độ sáng
/// dùng đúng mã màu của bản thiết kế; chế độ tối dùng bề mặt tối sẵn có của app
/// (để Trang chủ không lệch tông với các màn khác) và làm sáng các màu nhấn để
/// chữ vẫn đạt tương phản ≥ 4.5:1 (xem `test/calm_colors_test.dart`).
@immutable
class CalmColors extends ThemeExtension<CalmColors> {
  const CalmColors({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.green,
    required this.onGreen,
    required this.onGreenEyebrow,
    required this.onGreenMuted,
    required this.warm,
    required this.accent,
    required this.accentSoft,
    required this.streakCard,
    required this.streakIconBg,
    required this.streakIcon,
    required this.streakValue,
    required this.streakLabel,
    required this.xpCard,
    required this.xpIconBg,
    required this.xpIcon,
    required this.xpValue,
    required this.xpLabel,
    required this.notificationDot,
    required this.kanjiTile,
    required this.tagGreenBg,
    required this.tagGreen,
    required this.navInactive,
    required this.tiles,
  });

  final Color background;
  final Color card;
  final Color cardBorder;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;

  /// Nền thẻ "Bài học tiếp theo" và logo; chữ trên đó dùng [onGreen],
  /// [onGreenEyebrow], [onGreenMuted].
  final Color green;
  final Color onGreen;
  final Color onGreenEyebrow;
  final Color onGreenMuted;

  /// Điểm nhấn ấm: phần đã học của thanh tiến độ, mặt trời trong hình minh hoạ.
  final Color warm;

  /// Tím của hành động, liên kết, mục đang chọn; [accentSoft] là nền nhạt.
  final Color accent;
  final Color accentSoft;

  final Color streakCard;
  final Color streakIconBg;
  final Color streakIcon;
  final Color streakValue;
  final Color streakLabel;

  final Color xpCard;
  final Color xpIconBg;
  final Color xpIcon;
  final Color xpValue;
  final Color xpLabel;

  final Color notificationDot;
  final Color kanjiTile;
  final Color tagGreenBg;
  final Color tagGreen;
  final Color navInactive;

  final Map<StudyCornerTone, ({Color background, Color foreground})> tiles;

  static const light = CalmColors(
    background: AppPalette.background,
    card: AppPalette.card,
    cardBorder: AppPalette.cardBorder,
    divider: AppPalette.divider,
    textPrimary: AppPalette.textPrimary,
    textSecondary: AppPalette.textSecondary,
    green: AppPalette.green,
    onGreen: Colors.white,
    onGreenEyebrow: AppPalette.onGreenEyebrow,
    onGreenMuted: AppPalette.onGreenMuted,
    warm: AppPalette.warm,
    accent: AppPalette.purple,
    accentSoft: AppPalette.purpleSoft,
    streakCard: AppPalette.streakCard,
    streakIconBg: AppPalette.streakIconBg,
    streakIcon: AppPalette.streakIcon,
    streakValue: AppPalette.streakValue,
    streakLabel: AppPalette.streakLabel,
    xpCard: AppPalette.xpCard,
    xpIconBg: AppPalette.xpIconBg,
    xpIcon: AppPalette.xpIcon,
    xpValue: AppPalette.xpValue,
    xpLabel: AppPalette.xpLabel,
    notificationDot: AppPalette.notificationDot,
    kanjiTile: AppPalette.kanjiTile,
    tagGreenBg: AppPalette.tagGreenBg,
    tagGreen: AppPalette.tagGreen,
    navInactive: AppPalette.navInactive,
    tiles: {
      StudyCornerTone.lesson: (background: AppPalette.lessonBg, foreground: AppPalette.lessonFg),
      StudyCornerTone.vocabulary: (background: AppPalette.vocabularyBg, foreground: AppPalette.vocabularyFg),
      StudyCornerTone.kanji: (background: AppPalette.kanjiBg, foreground: AppPalette.kanjiFg),
      StudyCornerTone.exercise: (background: AppPalette.exerciseBg, foreground: AppPalette.exerciseFg),
      StudyCornerTone.jlpt: (background: AppPalette.jlptBg, foreground: AppPalette.jlptFg),
      StudyCornerTone.group: (background: AppPalette.groupBg, foreground: AppPalette.groupFg),
      StudyCornerTone.notebook: (background: AppPalette.notebookBg, foreground: AppPalette.notebookFg),
    },
  );

  static final dark = CalmColors(
    background: AppColors.darkBackground,
    card: AppColors.darkSurface,
    cardBorder: AppColors.darkBorder,
    divider: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    green: AppPalette.green,
    onGreen: Colors.white,
    onGreenEyebrow: AppPalette.onGreenEyebrow,
    onGreenMuted: AppPalette.onGreenMuted,
    warm: AppPalette.warm,
    accent: const Color(0xFFB9B1F7),
    accentSoft: const Color(0xFF2E2A5C),
    streakCard: const Color(0xFF3B2A20),
    streakIconBg: const Color(0xFF5A3A26),
    streakIcon: const Color(0xFFF2A267),
    streakValue: const Color(0xFFFBDCC6),
    streakLabel: const Color(0xFFE4B99C),
    xpCard: const Color(0xFF362F17),
    xpIconBg: const Color(0xFF55481F),
    xpIcon: const Color(0xFFE9C95F),
    xpValue: const Color(0xFFF7E7AE),
    xpLabel: const Color(0xFFDCC98A),
    notificationDot: const Color(0xFFF08A4B),
    kanjiTile: AppColors.darkSurfaceVariant,
    tagGreenBg: const Color(0xFF1E3A2C),
    tagGreen: const Color(0xFFA7D9BD),
    navInactive: AppColors.darkTextSecondary,
    tiles: {
      for (final entry in light.tiles.entries)
        entry.key: (
          background: Color.alphaBlend(entry.value.foreground.withValues(alpha: 0.28), AppColors.darkSurface),
          foreground: Color.lerp(entry.value.foreground, Colors.white, 0.55)!,
        ),
    },
  );

  static CalmColors of(BuildContext context) => Theme.of(context).extension<CalmColors>() ?? light;

  @override
  CalmColors copyWith() => this;

  /// Chỉ có hai bộ màu cố định, không cần nội suy từng màu khi đổi chế độ.
  @override
  CalmColors lerp(covariant CalmColors? other, double t) => t < 0.5 || other == null ? this : other;
}
