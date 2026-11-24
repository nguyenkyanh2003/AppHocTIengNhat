import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

/// Cài đặt của người đang đăng nhập — **một bản cho cả app**.
///
/// Màn Cài đặt, màn Cài đặt thông báo và những chỗ báo tin (huy hiệu mới, nhắc
/// học, thông báo mới) cùng đọc bản này, nên tắt "Âm thanh" ở đâu thì có tác
/// dụng ngay ở mọi nơi. Mỗi lần đổi được lưu ngay ([change]), không có nút Lưu
/// để quên bấm.
///
/// Chưa đọc được cài đặt thật thì không cho đổi: lưu lúc đó sẽ ghi đè bằng giá
/// trị mặc định, vì server nhận đủ năm trường một lần.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service}) : _service = service ?? SettingsService();

  final SettingsService _service;

  ViewState<UserSettings> _state = const ViewState.idle();

  /// Bản server đã nhận gần nhất; lưu hỏng thì trở về bản này.
  UserSettings? _saved;
  String? _userId;

  /// Đổi tài khoản hay đăng xuất thì tăng, để phản hồi của phiên cũ bị bỏ qua.
  int _session = 0;

  /// Các lần lưu chạy lần lượt: hai công tắc đổi liền tay không ghi đè nhau.
  Future<void> _saving = Future.value();
  int _pendingSaves = 0;
  bool _disposed = false;

  ViewState<UserSettings> get state => _state;

  /// Cài đặt đang hiện; chưa tải xong thì là giá trị mặc định.
  UserSettings get settings => _state.valueOrNull ?? const UserSettings();
  bool get isLoaded => _state.hasData;
  bool get isSaving => _pendingSaves > 0;

  /// Theo người đang đăng nhập: người mới thì tải, đăng xuất thì về mặc định.
  void syncUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _session++;
    _saved = null;
    _pendingSaves = 0;
    _saving = Future.value();
    _state = const ViewState.idle();
    _notify();
    if (userId != null) unawaited(load());
  }

  /// Tải cài đặt; trả câu báo lỗi nếu không tải được.
  Future<String?> load() async {
    final session = _session;
    _state = const ViewState.loading();
    _notify();
    final result = await ViewState.guard(_service.getSettings);
    if (session != _session) return null;
    _state = result;
    _saved = result.valueOrNull;
    _notify();
    return result.errorOrNull;
  }

  /// Đổi cài đặt: hiện ngay rồi lưu. Trả `null` khi server đã nhận; lưu hỏng
  /// thì trở về bản đã lưu gần nhất và trả câu báo lỗi.
  Future<String?> change(UserSettings Function(UserSettings current) edit) {
    final current = _state.valueOrNull;
    if (current == null) return Future.value('Chưa tải được cài đặt hiện tại.');
    _state = ViewState.data(edit(current));
    _pendingSaves++;
    _notify();

    final session = _session;
    final result = Completer<String?>();
    _saving = _saving.then((_) async {
      if (session != _session) return result.complete(null);
      // Gửi bản mới nhất lúc tới lượt: lần đổi sau đã nằm trong đó.
      final target = settings;
      final error = await ViewState.guard(() => _service.saveSettings(target)).then((saved) => saved.errorOrNull);
      if (session != _session) return result.complete(null);
      if (error == null) {
        _saved = target;
      } else if (_saved case final saved?) {
        _state = ViewState.data(saved);
      }
      _pendingSaves--;
      _notify();
      result.complete(error);
    });
    return result.future;
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
