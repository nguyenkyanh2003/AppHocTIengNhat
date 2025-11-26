import '../core/api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _client.post('/users/login', {
        'username': username,
        'password': password,
      });

      // Lưu token
      if (response['token'] != null) {
        await _client.setToken(response['token']);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng ký
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String phoneNumber,
  ) async {
    try {
      final response = await _client.post('/users/register', {
        'username': username,
        'email': email,
        'password': password,
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy thông tin user hiện tại
  Future<User> getCurrentUser(String userId) async {
    try {
      final response = await _client.get('/users/profile/$userId');
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _client.post('/users/logout', {});
    } catch (e) {
      // Ignore error khi logout
    } finally {
      await _client.removeToken();
      
      // Xóa user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    }
  }

  /// Cập nhật profile
  Future<User> updateProfile(
    String userId,
    {
      String? fullName,
      String? email,
      String? avatar,
      String? currentLevel,
      String? phoneNumber,
      String? address,
    }
  ) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['hoTen'] = fullName;
      if (email != null) data['email'] = email;
      if (avatar != null) data['anhDaiDien'] = avatar;
      if (currentLevel != null) data['trinhDo'] = currentLevel;
      if (phoneNumber != null) data['soDienThoai'] = phoneNumber;
      if (address != null) data['diaChi'] = address;

      final response = await _client.put('/auth/profile/$userId', data);
      return User.fromJson(response['profile']);
    } catch (e) {
      rethrow;
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword(
    String userId,
    String oldPassword, 
    String newPassword
  ) async {
    try {
      await _client.put('/users/change-password/$userId', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    try {
      await _client.post('/users/forgot-password', {
        'email': email,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Reset mật khẩu
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _client.post('/users/reset-password', {
        'token': token,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Lưu user vào local storage
  Future<void> saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  /// Lấy user từ local storage
  Future<User?> getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}