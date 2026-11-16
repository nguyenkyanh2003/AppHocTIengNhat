import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/models/user.dart';
import '../models/profile_changes.dart';
import '../services/auth_service.dart';

/// Phiên đăng nhập và người dùng hiện tại.
///
/// Mọi thao tác trả `null` khi xong hoặc câu báo lỗi (đã viết cho người dùng
/// đọc) để màn hiện tại chỗ.
class AuthProvider extends ChangeNotifier {
  /// Nhận service và client qua constructor để test truyền bản giả.
  AuthProvider({AuthService? authService, ApiClient? apiClient})
      : _authService = authService ?? AuthService(),
        _apiClient = apiClient ?? ApiClient() {
    _apiClient.onSessionExpired = _handleSessionExpired;
  }

  final AuthService _authService;
  final ApiClient _apiClient;

  User? _user;
  bool _busy = false;
  bool _sessionRestored = false;

  User? get user => _user;

  /// `true` khi một thao tác do người dùng bấm (đăng nhập, đổi mật khẩu, sửa
  /// hồ sơ...) đang chạy. Đừng dùng cờ này để quyết định điều hướng — xem
  /// [sessionRestored].
  bool get isBusy => _busy;

  /// `true` sau khi [init] chạy xong, bất kể có phiên hay không. Router chờ
  /// đúng cờ này rồi mới quyết định chuyển trang.
  bool get sessionRestored => _sessionRestored;
  bool get isAuthenticated => _user != null && _apiClient.getToken() != null;
  bool get isAdmin => _user?.role == 'admin';

  /// Khôi phục phiên đã lưu, rồi làm mới hồ sơ từ server nếu được.
  Future<void> init() async {
    try {
      if (_apiClient.getToken() != null) {
        _user = await _authService.getUserFromLocal();
        if (_user == null) {
          // Có token mà không có hồ sơ: phiên hỏng, dọn sạch để đăng nhập lại.
          await _clearLocalSession();
        } else {
          notifyListeners();
          await refreshUser();
        }
      }
    } finally {
      _sessionRestored = true;
      notifyListeners();
    }
  }

  Future<String?> login(String username, String password) => _run(() async {
        await _setUser(await _authService.login(username, password));
        // Làm mới hồ sơ để có vai trò mới nhất; lỗi thì vẫn dùng hồ sơ trong phiên.
        await refreshUser();
      });

  Future<String?> register(String username, String fullName, String email, String password, {String? level}) =>
      _run(() => _authService.register(
            username: username,
            fullName: fullName,
            email: email,
            password: password,
            level: level,
          ));

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Xoá state trên máy (đổi tài khoản). `sessionRestored` giữ nguyên: phiên
  /// đã khôi phục xong, xoá state không đưa ứng dụng về trạng thái khởi động.
  void resetState() {
    _user = null;
    notifyListeners();
  }

  Future<String?> updateProfile(ProfileChanges changes) =>
      _run(() async => _setUser(await _authService.updateProfile(_requireUser().id, changes)));

  Future<String?> uploadAvatar(List<int> imageBytes, String fileName) =>
      _run(() async => _setUser(await _authService.uploadAvatar(_requireUser().id, imageBytes, fileName)));

  /// Đổi mật khẩu của chính người dùng đang đăng nhập.
  ///
  /// Backend thu hồi mọi access token của tài khoản ngay khi đổi, nên xong là
  /// dọn phiên cục bộ — màn gọi phải đưa người dùng về đăng nhập. Không gọi API
  /// logout: token hiện tại đã chết, lỗi của request đó không được chặn việc dọn.
  Future<String?> changePassword(String oldPassword, String newPassword) => _run(() async {
        await _authService.changePassword(_requireUser().id, oldPassword, newPassword);
        await _clearLocalSession();
      });

  Future<String?> forgotPassword(String email) => _run(() => _authService.forgotPassword(email));

  Future<String?> resetPassword(String token, String newPassword) =>
      _run(() => _authService.resetPassword(token, newPassword));

  /// Làm mới hồ sơ từ server; lỗi thì giữ hồ sơ đang có.
  Future<void> refreshUser() async {
    final current = _user;
    if (current == null) return;
    final fresh = await ViewState.guard(() => _authService.getCurrentUser(current.id));
    if (fresh.valueOrNull case final user?) await _setUser(user);
  }

  Future<String?> _run(Future<void> Function() action) async {
    if (_busy) return 'Thao tác trước vẫn đang chạy.';
    _busy = true;
    notifyListeners();
    final result = await ViewState.guard(action);
    _busy = false;
    notifyListeners();
    return result.errorOrNull;
  }

  User _requireUser() => _user ?? (throw ApiException('Bạn chưa đăng nhập.'));

  Future<void> _setUser(User user) async {
    _user = user;
    await _authService.saveUserToLocal(user);
    notifyListeners();
  }

  /// Phiên ở server đã kết thúc (đổi mật khẩu, hết hạn): lỗi khi dọn kho trên
  /// máy không được biến việc đã xong thành "thất bại".
  Future<void> _clearLocalSession() async {
    _user = null;
    await ViewState.guard(() async {
      await _apiClient.removeToken();
      await _apiClient.clearAllData();
    });
  }

  /// Token hết hạn hoặc bị thu hồi: dọn phiên cục bộ rồi báo cho router, router
  /// thấy [isAuthenticated] về `false` sẽ tự chuyển sang màn đăng nhập.
  Future<void> _handleSessionExpired() async {
    if (_user == null && _apiClient.getToken() == null) return;
    await _clearLocalSession();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_apiClient.onSessionExpired == _handleSessionExpired) {
      _apiClient.onSessionExpired = null;
    }
    super.dispose();
  }
}
