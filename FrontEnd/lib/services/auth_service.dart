import '../core/api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final dynamic response = await _client.post('/users/login', {
        'username': username,
        'password': password,
      });

      if (response is Map<String, dynamic>) {
        // Lưu token
        if (response['token'] != null) {
          await _client.setToken(response['token']);
        }
        return response;
      }
      
      throw Exception('Phản hồi đăng nhập không hợp lệ');
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng ký
  Future<Map<String, dynamic>> register(
    String username,
    String fullName,
    String email,
    String password,
    String? phoneNumber,
    String? trinhDo,
  ) async {
    try {
      final dynamic response = await _client.post('/users/register', {
        'username': username,
        'hoTen': fullName,  // Backend yêu cầu field 'hoTen'
        'email': email,
        'password': password,
        if (trinhDo != null) 'trinhDo': trinhDo,
      });

      if (response is Map<String, dynamic>) {
        return response;
      }
      
      throw Exception('Phản hồi đăng ký không hợp lệ');
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy thông tin user hiện tại
  Future<User> getCurrentUser(String userId) async {
    try {
      final dynamic response = await _client.get('/users/profile/$userId');
      if (response is Map<String, dynamic>) {
        // API returns 'profile' not 'user'
        final userData = response['profile'] ?? response['user'];
        if (userData != null) {
          return User.fromJson(userData);
        }
      }
      throw Exception('Dữ liệu người dùng không hợp lệ');
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
      // Clear token
      await _client.removeToken();
      
      // Clear ALL user data for complete logout
      await _client.clearAllData();
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
      String? gender,
      DateTime? dateOfBirth,
    }
  ) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['hoTen'] = fullName;
      if (email != null) data['email'] = email;
      if (avatar != null) data['anhDaiDien'] = avatar;
      if (currentLevel != null) {
        // Backend expects "N5", "N4", etc., not just "5"
        data['trinhDo'] = currentLevel.startsWith('N') ? currentLevel : 'N$currentLevel';
      }
      if (phoneNumber != null) data['soDienThoai'] = phoneNumber;
      if (address != null) data['diaChi'] = address;
      if (gender != null) data['gioiTinh'] = gender;
      if (dateOfBirth != null) data['ngaySinh'] = dateOfBirth.toIso8601String();

      final dynamic response = await _client.put('/users/profile/$userId', data);
      if (response is Map<String, dynamic> && response['profile'] != null) {
        return User.fromJson(response['profile']);
      }
      throw Exception('Cập nhật profile không thành công');
    } catch (e) {
      rethrow;
    }
  }

  /// Upload avatar
  Future<User> uploadAvatar(String userId, List<int> imageBytes, String fileName) async {
    try {
      final dynamic response = await _client.putMultipart(
        '/users/profile/$userId/avatar',
        {},
        'avatar',
        imageBytes,
        fileName,
      );
      
      if (response is Map<String, dynamic> && response['profile'] != null) {
        return User.fromJson(response['profile']);
      }
      throw Exception('Cập nhật avatar không thành công');
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
    // Lưu user data theo userId để tránh ghi đè khi có nhiều tài khoản
    await prefs.setString('user_data_${user.id}', json.encode(user.toJson()));
    // Lưu userId hiện tại để biết user nào đang đăng nhập
    await prefs.setString('current_user_id', user.id);
  }

  /// Lấy user từ local storage
  Future<User?> getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lấy userId của user hiện tại
      final currentUserId = prefs.getString('current_user_id');
      if (currentUserId == null) return null;
      
      // Lấy dữ liệu user theo userId
      final userData = prefs.getString('user_data_$currentUserId');
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}