import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('vi', 'VN');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  /// Tải ngôn ngữ đã lưu từ SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'vi';

      switch (languageCode) {
        case 'en':
          _locale = const Locale('en', 'US');
          break;
        case 'ja':
          _locale = const Locale('ja', 'JP');
          break;
        case 'vi':
        default:
          _locale = const Locale('vi', 'VN');
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  /// Thay đổi ngôn ngữ
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Lưu vào SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Thay đổi ngôn ngữ bằng language code
  Future<void> setLanguage(String languageCode) async {
    Locale newLocale;
    switch (languageCode) {
      case 'en':
        newLocale = const Locale('en', 'US');
        break;
      case 'ja':
        newLocale = const Locale('ja', 'JP');
        break;
      case 'vi':
      default:
        newLocale = const Locale('vi', 'VN');
        break;
    }
    await setLocale(newLocale);
  }
}
