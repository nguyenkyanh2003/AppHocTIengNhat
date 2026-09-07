import 'package:flutter/material.dart';
import '../../../shared/models/user.dart';
import '../../auth/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Tải thông tin người dùng hiện tại
  Future<void> loadCurrentUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUser(userId);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải thông tin người dùng';
      debugPrint('Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin người dùng
  Future<void> updateUserProfile({
    required String userId,
    required String hoTen,
    String? email,
    String? soDienThoai,
    String? anhDaiDien,
    String? diaChi,
    String? gioiTinh,
    DateTime? ngaySinh,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        userId,
        fullName: hoTen,
        email: email,
        avatar: anhDaiDien,
        phoneNumber: soDienThoai,
        address: diaChi,
        gender: gioiTinh,
        dateOfBirth: ngaySinh,
      );
      _error = null;
    } catch (e) {
      _error = 'Không thể cập nhật thông tin người dùng';
      debugPrint('Error updating user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword(
      String userId, String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(userId, currentPassword, newPassword);
      _error = null;
    } catch (e) {
      _error = 'Không thể đổi mật khẩu';
      debugPrint('Error changing password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa tài khoản
  Future<void> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Không thể xóa tài khoản';
      debugPrint('Error deleting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đặt lại dữ liệu
  void reset() {
    _user = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
