import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../shared/models/user.dart';
import '../models/profile_changes.dart';

class AuthService {
  /// Nhận client qua constructor để test truyền transport giả.
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Đăng nhập và lưu phiên: access token sống 15 phút, refresh token để tự
  /// đổi cặp mới khi hết hạn.
  Future<User> login(String username, String password) async {
    final session = objectOf(
      await _client.post('/users/login', {'username': username, 'password': password}),
      (json) => (
        user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String?,
      ),
    );
    await _client.setSession(session.token, session.refreshToken);
    return session.user;
  }

  Future<User> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    String? level,
  }) async {
    final response = await _client.post('/users/register', {
      'username': username,
      'hoTen': fullName,
      'email': email,
      'password': password,
      if (level != null) 'trinhDo': level,
    });
    return objectOf(response, User.fromJson);
  }

  Future<User> getCurrentUser(String userId) async =>
      objectOf(await _client.get('/users/profile/$userId'), User.fromJson);

  /// Đăng xuất: gửi refresh token (và access token trong header) để server
  /// đóng đúng phiên của thiết bị này. Lỗi mạng không chặn việc dọn phiên cục bộ.
  Future<void> logout() async {
    try {
      final refreshToken = _client.getRefreshToken();
      await _client.post('/users/logout', {if (refreshToken != null) 'refreshToken': refreshToken});
    } catch (_) {
      // Phiên trên máy vẫn được dọn bên dưới; server tự hết hạn phiên bỏ dở.
    } finally {
      await _client.removeToken();
      await _client.clearAllData();
    }
  }

  Future<User> updateProfile(String userId, ProfileChanges changes) async =>
      objectOf(await _client.put('/users/profile/$userId', changes.toJson()), User.fromJson);

  Future<User> uploadAvatar(String userId, List<int> imageBytes, String fileName) async => objectOf(
        await _client.putMultipart('/users/profile/$userId/avatar', const {}, 'avatar', imageBytes, fileName),
        User.fromJson,
      );

  Future<void> changePassword(String userId, String oldPassword, String newPassword) =>
      _client.put('/users/change-password/$userId', {'oldPassword': oldPassword, 'newPassword': newPassword});

  Future<void> forgotPassword(String email) => _client.post('/users/forgot-password', {'email': email});

  Future<void> resetPassword(String token, String newPassword) =>
      _client.post('/users/reset-password', {'token': token, 'newPassword': newPassword});

  /// Lưu user theo id để nhiều tài khoản trên cùng máy không ghi đè nhau.
  Future<void> saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data_${user.id}', json.encode(user.toJson()));
    await prefs.setString('current_user_id', user.id);
  }

  Future<User?> getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');
      if (currentUserId == null) return null;
      final userData = prefs.getString('user_data_$currentUserId');
      return userData == null ? null : User.fromJson(json.decode(userData) as Map<String, dynamic>);
    } catch (_) {
      // Bản lưu hỏng thì coi như chưa đăng nhập: người dùng đăng nhập lại.
      return null;
    }
  }
}
