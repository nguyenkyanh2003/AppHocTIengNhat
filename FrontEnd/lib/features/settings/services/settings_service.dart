import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/user_settings.dart';

class SettingsService {
  SettingsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Cài đặt của người đang đăng nhập; trường server không trả về lấy mặc định.
  Future<UserSettings> getSettings() async => objectOf(await _client.get('/settings'), UserSettings.fromJson);

  /// Lưu đủ năm cài đặt một lần — server từ chối bản thiếu trường.
  Future<void> saveSettings(UserSettings settings) => _client.post('/settings', settings.toJson());
}
