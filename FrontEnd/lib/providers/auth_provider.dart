import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart'; 
import '../models/user.dart';

/// Provider quản lý trạng thái đăng nhập và user
class AuthProvider extends ChangeNotifier {
  // Lưu ý: Đảm bảo tên class bên file service khớp với chỗ này (AuthService)
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && ApiClient().getToken() != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isTeacher => _user?.role == 'teacher' || _user?.role == 'admin';

  /// Khởi tạo - Load user từ storage và API
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (ApiClient().getToken() != null) {
        _user = await _authService.getUserFromLocal();
        notifyListeners();
        try {
          _user = await _authService.getCurrentUser(_user!.id);
          await _authService.saveUserToLocal(_user!);
        } catch (e) {
          // ✅ Đã sửa: Dùng debugPrint thay vì print
          debugPrint('Failed to refresh user from API: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      // ✅ Đã sửa
      debugPrint('Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authService.login(username, password);
      
      if (response['user'] != null) {
        _user = User.fromJson(response['user']);
        await _authService.saveUserToLocal(_user!);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Đăng ký
  Future<bool> register(String username, String email, String password, String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.register(username, email, password, phoneNumber);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
    } catch (e) {
      // ✅ Đã sửa
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Cập nhật profile
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? avatar,
    int? currentLevel, 
    String? phoneNumber,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_user == null) {
        throw Exception('Chưa đăng nhập');
      }
      
      // Giả định AuthService nhận tham số ID đầu tiên và các tham số named arguments
      _user = await _authService.updateProfile(
        _user!.id, 
        fullName: fullName,
        email: email,
        avatar: avatar,
       currentLevel: currentLevel?.toString(),
        phoneNumber: phoneNumber,
        address: address,
      );
      
      await _authService.saveUserToLocal(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Đổi mật khẩu
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_user == null) {
        throw Exception('Chưa đăng nhập');
      }
      
      await _authService.changePassword(_user!.id, oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Quên mật khẩu - Gửi email reset
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Reset mật khẩu với token
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.resetPassword(token, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Refresh user data từ API
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    
    try {
      _user = await _authService.getCurrentUser(_user!.id);
      await _authService.saveUserToLocal(_user!);
      notifyListeners();
    } catch (e) {
      // ✅ Đã sửa
      debugPrint('Refresh user error: $e');
    }
  }
  
  /// Clear lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Xử lý error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('401')) {
      return 'Tên đăng nhập hoặc mật khẩu không đúng';
    } else if (errorString.contains('400')) {
      return 'Thông tin không hợp lệ';
    } else if (errorString.contains('409')) {
      return 'Tên đăng nhập hoặc email đã tồn tại';
    } else if (errorString.contains('404')) {
      return 'Không tìm thấy thông tin';
    } else if (errorString.contains('500')) {
      return 'Lỗi server, vui lòng thử lại sau';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Lỗi kết nối mạng';
    } else {
      return 'Đã có lỗi xảy ra: $errorString';
    }
  }
}