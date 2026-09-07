import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bộ nhớ đệm nội dung cho chế độ ngoại tuyến.
///
/// Tách khỏi `ApiClient` để client HTTP chỉ lo việc gọi mạng. Quan trọng hơn:
/// trước đây client tự giữ danh sách endpoint được cache, nên muốn cache thêm
/// một màn hình phải sửa vào lớp hạ tầng. Giờ nơi gọi tự khai `cache: true`.
class OfflineCache {
  static const _enabledKey = 'offline_mode_enabled';
  static const storageKey = 'offline_content_cache_v1';
  static const _maxEntries = 50;

  static final OfflineCache _instance = OfflineCache._internal();

  factory OfflineCache() => _instance;
  OfflineCache._internal();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<dynamic> read(String key) async {
    final entry = (await _readAll())[key];
    return entry is Map ? entry['data'] : null;
  }

  Future<void> write(String key, dynamic value) async {
    final cache = await _readAll();
    cache[key] = {
      'cachedAt': DateTime.now().toIso8601String(),
      'data': value,
    };
    if (cache.length > _maxEntries) cache.remove(cache.keys.first);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(cache));
  }

  /// Các key đang được lưu, dùng để làm mới toàn bộ cache.
  Future<List<String>> keys() async => (await _readAll()).keys.toList();

  Future<Map<String, dynamic>> info() async {
    final cache = await _readAll();
    DateTime? latest;

    for (final entry in cache.values) {
      if (entry is! Map || entry['cachedAt'] is! String) continue;
      final date = DateTime.tryParse(entry['cachedAt'] as String);
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }

    return {
      'items': cache.length,
      'bytes': utf8.encode(jsonEncode(cache)).length,
      'lastSync': latest,
    };
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return {};

    try {
      final decoded = jsonDecode(encoded);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      await prefs.remove(storageKey);
      return {};
    }
  }
}
