import 'package:flutter/material.dart';

export 'app_theme_colors.dart';

/// Design token của ứng dụng.
///
/// Mọi màu, khoảng cách, bo góc và thời lượng animation đều lấy từ đây. Screen
/// và widget không tự đặt `Color(0x...)`, `EdgeInsets.all(17)` hay `Duration`
/// rời rạc — nếu thiếu giá trị nào thì bổ sung token mới ở file này.
abstract final class AppColors {
  // Thương hiệu. `primary` là màu của giao diện; `accent` chỉ dành cho những gì
  // đo sự tiến bộ của người học (streak, XP, thanh tiến độ) — tách hai vai này
  // ra để "app đang nói" và "bạn đang tiến bộ" không dùng chung một màu.
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFFF59E0B);

  // Ngữ nghĩa
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  /// Nền đặc mang chữ trắng: bản gốc chỉ đạt 2,5:1 (success), 2,2:1 (warning),
  /// 3,8:1 (error). Ba bản này đạt từ 4,5:1 trở lên ở cả hai chế độ.
  static const Color successStrong = Color(0xFF047857);
  static const Color warningStrong = Color(0xFFB45309);
  static const Color errorStrong = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Bề mặt - chế độ sáng. Thang trung tính ngả xanh để hoà với primary, thay vì
  // xám trung tính chọi với mọi màu thương hiệu.
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Chữ - chế độ sáng
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Bề mặt - chế độ tối
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  // Sáng hơn thẻ nhưng còn đủ tối để chữ phụ trên ô nhập liệu đạt 4.5:1.
  static const Color darkSurfaceVariant = Color(0xFF2A3950);
  static const Color darkBorder = Color(0xFF334155);

  // Chữ - chế độ tối
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextDisabled = Color(0xFF7C8BA1);

  // Thương hiệu - chế độ tối. `primary` quá tối để làm chữ hay icon trên nền tối
  // (2.3:1), nên ở đó dùng bản sáng hơn; làm nền nút có chữ trắng thì vẫn giữ.
  static const Color darkPrimary = Color(0xFFA5B4FC);
  static const Color darkPrimaryStrong = Color(0xFFC7D2FE);
  static const Color darkPrimarySoft = Color(0xFF2E2A5C);
  static const Color darkOnPrimary = Color(0xFF1E1B4B);
  static const Color darkError = Color(0xFFFCA5A5);

  // Màu nhận diện từng mảng nội dung. Cùng một mức bão hoà nên các thẻ đứng
  // cạnh nhau không chọi, khác hẳn bảng Material gốc mỗi màu một cường độ.
  static const Color vocabulary = Color(0xFF4F46E5);
  static const Color grammar = Color(0xFF10B981);
  static const Color kanji = Color(0xFFF59E0B);
  static const Color lesson = Color(0xFFEC4899);
  static const Color exercise = Color(0xFF8B5CF6);
  static const Color jlpt = Color(0xFF6366F1);
  static const Color notebook = Color(0xFFEAB308);
  static const Color news = Color(0xFF0EA5E9);
  static const Color group = Color(0xFF14B8A6);
  static const Color progress = Color(0xFF22C55E);

  /// Hai chỉ số học tập ở Trang chủ. Hai sắc khác nhau để hai thẻ đứng cạnh
  /// nhau không dính thành một khối màu: chuỗi ngày là cam lửa, XP là hổ phách.
  /// Cả hai đều đủ tối để chữ mực đậm đọc rõ trên nền thẻ.
  static const Color streak = Color(0xFFFF9600);
  static const Color xp = Color(0xFFFFC800);

  /// Băng bảo vệ chuỗi: xanh băng, tách khỏi cam của chuỗi để ngày "được băng
  /// che" không bị đọc nhầm thành ngày đã học trên lịch.
  static const Color freeze = Color(0xFF38BDF8);

  /// Hành động chính của Trang chủ ("Tiếp tục học"). Xanh lá đứng tách khỏi tím
  /// thương hiệu, nên mắt tìm ra ngay việc cần làm tiếp thay vì phải đọc hết.
  static const Color heroAction = Color(0xFF58CC02);

  /// Xám đậm cố định: nền đặc có chữ trắng và màu mặc định của nhãn trạng thái.
  /// Làm chữ thì đi qua `context.colors.readable`.
  static const Color neutral = Color(0xFF475569);

  /// Mực đậm cố định, dùng trên nền rực không đổi theo chế độ (cam chuỗi ngày, xanh
  /// băng) và làm nền khung video.
  static const Color ink = Color(0xFF0F172A);

  /// Màu riêng của các màn Kanji.
  static const Color kanjiCoral = Color(0xFFFF6B6B);
  static const Color kanjiCoralEnd = Color(0xFFFF8E53);

  /// Độ hiếm của huy hiệu; nền đặc có chữ trắng ở cả hai chế độ.
  static const Color rarityLegendary = Color(0xFFB45309);
  static const Color rarityLegendaryEnd = Color(0xFF92400E);
  static const Color rarityEpic = Color(0xFF7C3AED);
  static const Color rarityEpicEnd = Color(0xFF6D28D9);
  static const Color rarityRare = Color(0xFF4F46E5);
  static const Color rarityRareEnd = Color(0xFF4338CA);
  static const Color rarityCommon = Color(0xFF64748B);
  static const Color rarityCommonEnd = Color(0xFF475569);

  /// Huy chương ba hạng đầu bảng xếp hạng.
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalGoldEnd = Color(0xFFFFAA00);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalSilverEnd = Color(0xFF999999);
  static const Color medalBronze = Color(0xFFCD7F32);
  static const Color medalBronzeEnd = Color(0xFF8B4513);

  /// Nền đặc của khối chuỗi ngày ở Lịch sử học và nút đăng nhập.
  static const Color historyHeroStart = Color(0xFF667EEA);
  static const Color historyHeroEnd = Color(0xFF764BA2);
  static const Color authButtonEnd = Color(0xFF1565C0);

  /// Bốn mức của lịch hoạt động, ít tới nhiều. Chế độ sáng đậm dần so với ô trống
  /// sáng màu; chế độ tối sáng dần so với ô trống tối màu.
  static const List<Color> heatmapLight = [
    Color(0xFFA7E3BE),
    Color(0xFF5CC98E),
    Color(0xFF2A9D66),
    Color(0xFF14663F),
  ];
  static const List<Color> heatmapDark = [
    Color(0xFF2E7D5B),
    Color(0xFF34A36F),
    Color(0xFF4CC98A),
    Color(0xFF86EFAC),
  ];

  /// Chữ hoặc icon đặt trên nền đặc [fill]: trắng khi đủ tương phản, không thì
  /// chữ tối. Màu lục, vàng, cam với chữ trắng chỉ đạt khoảng 2:1.
  static Color onFill(Color fill) {
    final light = fill.computeLuminance();
    return 1.05 / (light + 0.05) >= 4.5 ? Colors.white : ink;
  }

  /// Màu cấp độ JLPT, từ dễ (N5) đến khó (N1).
  static const Map<String, Color> jlptLevels = {
    'N5': Color(0xFF10B981),
    'N4': Color(0xFF22C55E),
    'N3': Color(0xFFEAB308),
    'N2': Color(0xFFF59E0B),
    'N1': Color(0xFFEF4444),
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
  static const Widget xs =
      SizedBox(height: AppSpacing.xs, width: AppSpacing.xs);
  static const Widget sm =
      SizedBox(height: AppSpacing.sm, width: AppSpacing.sm);
  static const Widget md =
      SizedBox(height: AppSpacing.md, width: AppSpacing.md);
  static const Widget lg =
      SizedBox(height: AppSpacing.lg, width: AppSpacing.lg);
  static const Widget xl =
      SizedBox(height: AppSpacing.xl, width: AppSpacing.xl);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// Bo góc thẻ nổi khối kiểu Duolingo (`ChunkyCard`) — lớn hơn hẳn thẻ phẳng
  /// thường ([lg]) để tạo cảm giác đồ chơi, thân thiện.
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
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

/// Bề rộng tối đa của vùng nội dung, theo loại nội dung.
///
/// Ba mức tách biệt vì biểu mẫu, nội dung đọc và dashboard có nhu cầu khác
/// nhau: kéo một biểu mẫu ra 1200px làm mắt phải quét ngang vô ích, còn ép
/// dashboard xuống 720px thì mất chỗ cho biểu đồ.
abstract final class AppContentWidth {
  /// Biểu mẫu, đăng nhập, hộp thoại nhập liệu.
  static const double form = 480;

  /// Nội dung đọc: chi tiết từ vựng, ngữ pháp, bài học, tin tức.
  static const double reading = 720;

  /// Bảng tin một cột (Trang chủ). Hẹp hơn [reading] để thẻ và lưới hai cột
  /// giữ đúng tỉ lệ như trên điện thoại thay vì bè ra trên màn hình rộng.
  static const double feed = 640;

  /// Trang chi tiết hai cột (chi tiết từ vựng): rộng hơn [reading] để đặt
  /// thẻ từ bên cạnh phần mở rộng, hẹp hơn [dashboard] để mắt không phải
  /// quét quá xa giữa hai cột.
  static const double detail = 960;

  /// Dashboard, bảng quản trị, lưới thẻ.
  static const double dashboard = 1200;
}

/// Mốc chuyển bố cục, tính theo bề rộng **cửa sổ**.
///
/// Các mốc dưới đây được suy ra từ diện tích còn lại sau khi trừ thanh điều
/// hướng và lề trang, không lấy theo một bảng có sẵn:
///
/// | Mốc | Phép tính | Kết quả |
/// | --- | --- | --- |
/// | [rail] 600 | 600 − 80 (rail thu gọn) − 2×16 (lề) | 488 ≥ [AppContentWidth.form] |
/// | [railExtended] 1024 | 1024 − 256 (rail mở rộng) − 2×24 (lề) | 720 = [AppContentWidth.reading] |
/// | [twoColumn] 1440 | 1440 − 256 − 2×24 | 1136 → hai cột 556 + khe 24 |
///
/// Đổi [railWidth] hay [railExtendedWidth] thì phải tính lại các mốc này.
abstract final class AppBreakpoints {
  /// Dưới mốc này dùng thanh điều hướng dưới; từ mốc này dùng rail thu gọn.
  static const double rail = 600;

  /// Từ mốc này rail hiện cả nhãn.
  static const double railExtended = 1024;

  /// Từ mốc này vùng nội dung đủ rộng để chia hai cột.
  static const double twoColumn = 1440;

  /// Bề rộng rail thu gọn (Material 3: 80).
  static const double railWidth = 80;

  /// Bề rộng rail mở rộng.
  static const double railExtendedWidth = 256;
}

/// Bảng màu dịu của Trang chủ (thiết kế 2026-09): nền kem ấm, xanh lá đậm cho
/// hành động chính, tím cho thao tác và liên kết, cam/vàng dịu cho chuỗi ngày
/// và XP. Giảm độ rực so với bảng màu Duolingo cũ nhưng giữ nguyên ý nghĩa
/// từng màu.
///
/// Đây là giá trị thô cho chế độ sáng. Widget không đọc thẳng từ đây mà qua
/// `CalmColors.of(context)` để chế độ tối có bộ màu riêng.
abstract final class AppPalette {
  static const Color background = Color(0xFFF6F5F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE7E5DC);
  static const Color divider = Color(0xFFEEECE4);
  static const Color textPrimary = Color(0xFF1C2A22);
  static const Color textSecondary = Color(0xFF5B6660);

  static const Color green = Color(0xFF1D6B48);
  static const Color onGreenEyebrow = Color(0xFFCDE8D8);
  static const Color onGreenMuted = Color(0xFFDCEFE3);
  static const Color warm = Color(0xFFF4C58B);

  static const Color purple = Color(0xFF4B3FB0);
  static const Color purpleSoft = Color(0xFFECE9FB);

  static const Color streakCard = Color(0xFFFDEEE2);
  static const Color streakIconBg = Color(0xFFF9D9C0);
  static const Color streakIcon = Color(0xFFB8531C);
  static const Color streakValue = Color(0xFF7A3413);
  static const Color streakLabel = Color(0xFF8C5A3C);
  static const Color notificationDot = Color(0xFFD0652A);

  static const Color xpCard = Color(0xFFFBF3D6);
  static const Color xpIconBg = Color(0xFFF5E6AE);
  static const Color xpIcon = Color(0xFF9A7208);
  static const Color xpValue = Color(0xFF6B4E00);
  static const Color xpLabel = Color(0xFF7A6420);

  static const Color kanjiTile = Color(0xFFF4F2EC);
  static const Color tagGreenBg = Color(0xFFEAF3EE);
  static const Color tagGreen = Color(0xFF1D5C3E);

  static const Color navInactive = Color(0xFF4A5550);

  /// Hình minh hoạ núi Phú Sĩ trên thẻ "Bài học tiếp theo" (vẽ bằng code, nền
  /// trong suốt): hai lớp núi sáng dần lên nền xanh và chóp tuyết.
  static const Color illustrationHill = Color(0xFF2A7C57);
  static const Color illustrationMountain = Color(0xFF4A9A74);
  static const Color illustrationSnow = Color(0xFFF1F7F3);

  /// Màu từng ô ở "Góc học tập": nền nhạt / icon.
  static const Color lessonBg = Color(0xFFEAF3EE);
  static const Color lessonFg = green;
  static const Color vocabularyBg = purpleSoft;
  static const Color vocabularyFg = purple;
  static const Color kanjiBg = Color(0xFFFDEEE2);
  static const Color kanjiFg = Color(0xFFB8531C);
  static const Color exerciseBg = Color(0xFFE6EEF8);
  static const Color exerciseFg = Color(0xFF2F5E9E);
  static const Color jlptBg = Color(0xFFFBF3D6);
  static const Color jlptFg = Color(0xFF8A6508);
  static const Color groupBg = Color(0xFFE3F2F0);
  static const Color groupFg = Color(0xFF1F6F66);
  static const Color notebookBg = Color(0xFFF8E8EC);
  static const Color notebookFg = Color(0xFFA33E5C);
}
