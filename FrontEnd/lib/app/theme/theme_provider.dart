import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lựa chọn giao diện sáng / tối / theo hệ thống.
///
/// Đây là cài đặt của **thiết bị**, nên nằm trong SharedPreferences và ở lại sau
/// khi đăng xuất, giống ngôn ngữ. `settings.theme` trên server không dùng để đọc
/// lại: schema gán mặc định `light` cho mọi tài khoản, nên không phân biệt được
/// người đã chọn Sáng với người chưa chọn gì.
class ThemeProvider with ChangeNotifier {
  ThemeProvider([this._mode = ThemeMode.system]);

  static const storageKey = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Đọc lựa chọn đã lưu. `main` gọi hàm này trước `runApp` để khung hình đầu
  /// tiên đã đúng giao diện, không loé sang chế độ kia. Lỗi đọc kho thì theo hệ
  /// thống: không để một cài đặt giao diện chặn app khởi động.
  static Future<ThemeMode> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _modeOf(prefs.getString(storageKey));
    } catch (error) {
      debugPrint('Không đọc được lựa chọn giao diện: $error');
      return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, valueOf(mode));
    } catch (error) {
      debugPrint('Không lưu được lựa chọn giao diện: $error');
    }
  }

  /// Giá trị dùng trong kho và trong `settings.theme` của backend.
  static String valueOf(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'auto',
      };

  static ThemeMode _modeOf(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
