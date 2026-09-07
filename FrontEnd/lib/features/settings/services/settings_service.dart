import '../../../core/network/api_client.dart';

class SettingsService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy cài đặt của người dùng
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiClient.get('/settings');
    return {
      'notificationsEnabled': response['notificationsEnabled'] ?? true,
      'soundEnabled': response['soundEnabled'] ?? true,
      'vibrateEnabled': response['vibrateEnabled'] ?? true,
      'language': response['language'] ?? 'vi',
      'theme': response['theme'] ?? 'light',
    };
  }

  /// Lưu cài đặt của người dùng
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _apiClient.post('/settings', settings);
  }

  /// Cập nhật một cài đặt cụ thể
  Future<void> updateSetting(String setting, dynamic value) async {
    await _apiClient.patch('/settings/$setting', {'value': value});
  }
}
