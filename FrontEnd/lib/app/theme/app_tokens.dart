import 'package:flutter/material.dart';

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
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);

  // Chữ - chế độ tối
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextDisabled = Color(0xFF64748B);

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

  /// Hành động chính của Trang chủ ("Tiếp tục học"). Xanh lá đứng tách khỏi tím
  /// thương hiệu, nên mắt tìm ra ngay việc cần làm tiếp thay vì phải đọc hết.
  static const Color heroAction = Color(0xFF58CC02);

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
