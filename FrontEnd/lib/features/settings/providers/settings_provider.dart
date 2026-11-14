import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

/// Cài đặt người dùng đang sửa trên màn hình, và lần lưu đang chạy.
///
/// Thay đổi chỉ nằm trên máy cho tới khi gọi [save]. Chưa đọc được cài đặt thật
/// thì không cho sửa hay lưu: lưu lúc đó sẽ ghi đè bằng giá trị mặc định.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service}) : _service = service ?? SettingsService();

  final SettingsService _service;

  ViewState<UserSettings> _state = const ViewState.idle();
  bool _saving = false;
  bool _disposed = false;

  ViewState<UserSettings> get state => _state;

  /// Cài đặt đang hiện; chưa tải xong thì là giá trị mặc định.
  UserSettings get settings => _state.valueOrNull ?? const UserSettings();
  bool get isLoaded => _state.hasData;
  bool get isSaving => _saving;
  bool get canSave => isLoaded && !_saving;

  /// Tải cài đặt; trả câu báo lỗi nếu không tải được.
  Future<String?> load() async {
    _state = const ViewState.loading();
    _notify();
    _state = await ViewState.guard(_service.getSettings);
    _notify();
    return _state.errorOrNull;
  }

  void update(UserSettings Function(UserSettings current) change) {
    final current = _state.valueOrNull;
    if (current == null) return;
    _state = ViewState.data(change(current));
    _notify();
  }

  /// Lưu cài đặt đang hiện, kèm [theme] của máy nếu có; trả `null` khi đã lưu,
  /// hoặc câu báo lỗi.
  Future<String?> save({String? theme}) async {
    final current = _state.valueOrNull;
    if (current == null) return 'Chưa tải được cài đặt hiện tại.';
    if (_saving) return 'Đang lưu cài đặt.';
    _saving = true;
    _notify();
    try {
      await _service.saveSettings(theme == null ? current : current.copyWith(theme: theme));
      return null;
    } catch (error) {
      return userMessageOf(error);
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
