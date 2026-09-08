import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/services/auth_service.dart';
import 'package:apphoctiengnnhat/shared/models/user.dart';

User _user() => User(
      id: 'user-1',
      username: 'victim',
      email: 'victim@example.com',
      role: 'user',
      createdAt: DateTime(2026, 1, 1),
    );

/// Service giả: không chạm mạng, ghi lại mọi lời gọi.
class _FakeAuthService extends AuthService {
  final List<List<String>> changePasswordCalls = [];
  final List<List<String>> resetPasswordCalls = [];
  int logoutCalls = 0;

  Object? changePasswordError;
  Object? resetPasswordError;

  @override
  Future<void> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    changePasswordCalls.add([userId, oldPassword, newPassword]);
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    resetPasswordCalls.add([token, newPassword]);
    if (resetPasswordError != null) throw resetPasswordError!;
  }

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    return {
      'user': {
        '_id': 'user-1',
        'TenDangNhap': 'victim',
        'Email': 'victim@example.com',
        'VaiTro': 'user',
      },
      'token': 'jwt-token',
    };
  }

  @override
  Future<User> getCurrentUser(String userId) async => _user();

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  Future<void> saveUserToLocal(User user) async {}

  @override
  Future<User?> getUserFromLocal() async => null;
}

/// Đưa provider về trạng thái "đang đăng nhập" qua đúng luồng đăng nhập,
/// không cần API test riêng trong code sản phẩm.
Future<AuthProvider> _signedInProvider(_FakeAuthService service) async {
  final provider = AuthProvider(authService: service);
  await provider.login('victim', 'correct-horse');
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('đổi mật khẩu', () {
    test('đổi thành công thì dọn phiên cục bộ', () async {
      final service = _FakeAuthService();
      final provider = await _signedInProvider(service);

      final ok = await provider.changePassword('cu', 'mat-khau-moi');

      expect(ok, isTrue);
      expect(service.changePasswordCalls, [
        ['user-1', 'cu', 'mat-khau-moi'],
      ]);
      // Token đã bị backend thu hồi, phiên cục bộ phải bị xoá theo.
      expect(provider.user, isNull);
      expect(provider.isAuthenticated, isFalse);
    });

    test('không gọi API logout bằng token đã bị thu hồi', () async {
      final service = _FakeAuthService();
      final provider = await _signedInProvider(service);

      await provider.changePassword('cu', 'mat-khau-moi');

      expect(service.logoutCalls, 0);
    });

    test('đổi thất bại thì giữ nguyên phiên và có thông báo lỗi', () async {
      final service = _FakeAuthService()
        ..changePasswordError = UnauthorizedException('Mật khẩu cũ không chính xác.');
      final provider = await _signedInProvider(service);

      final ok = await provider.changePassword('sai', 'mat-khau-moi');

      expect(ok, isFalse);
      expect(provider.user, isNotNull);
      expect(provider.error, isNotNull);
    });

    test('chưa đăng nhập thì không gửi request nào', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(authService: service);

      final ok = await provider.changePassword('cu', 'moi');

      expect(ok, isFalse);
      expect(service.changePasswordCalls, isEmpty);
    });
  });

  group('đặt lại mật khẩu', () {
    test('gửi đúng token và mật khẩu mới', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(authService: service);

      final ok = await provider.resetPassword('token-abc', 'mat-khau-moi');

      expect(ok, isTrue);
      expect(service.resetPasswordCalls, [
        ['token-abc', 'mat-khau-moi'],
      ]);
    });

    test('token đặt lại không được lưu vào chỗ giữ access token', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(authService: service);

      await provider.resetPassword('token-abc', 'mat-khau-moi');

      expect(ApiClient().getToken(), isNull);
    });

    test('token hết hạn hoặc đã dùng trả về lỗi đọc được', () async {
      final service = _FakeAuthService()
        ..resetPasswordError =
            UnauthorizedException('Token đã được sử dụng hoặc không còn hợp lệ.');
      final provider = AuthProvider(authService: service);

      final ok = await provider.resetPassword('token-cu', 'mat-khau-moi');

      expect(ok, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, isNot(contains('Exception:')));
    });
  });
}
