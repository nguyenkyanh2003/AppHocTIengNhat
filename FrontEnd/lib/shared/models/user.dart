import '../../core/network/api_client.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatar;
  final String role;
  final String? currentLevel;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? status;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatar,
    required this.role,
    this.currentLevel,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.status,
    required this.createdAt,
    this.lastLogin,
  });

  // Helper function to parse datetime strings from backend (format: "2025-11-25 21:48:28")
  static DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // Try parsing with space separator (backend format)
      if (dateStr.contains(' ') && !dateStr.contains('T')) {
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          return DateTime.parse('${parts[0]}T${parts[1]}');
        }
      }
      // Try standard ISO format
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final avatarUrl = ApiClient.resolveAssetUrl(
      json['AnhDaiDien'] ?? json['avatar'],
    );

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['TenDangNhap'] ?? json['username'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      fullName: json['HoTen'] ?? json['fullName'],
      avatar: avatarUrl,
      role: json['VaiTro'] ?? json['role'] ?? 'user',
      currentLevel: json['TrinhDo'] ?? json['currentLevel'],
      phone: json['SoDienThoai'] ?? json['phone'],
      address: json['DiaChi'] ?? json['address'],
      dateOfBirth: _parseDateTime(json['NgaySinh']) ??
          _parseDateTime(json['dateOfBirth']),
      gender: json['GioiTinh'] ?? json['gender'],
      status: json['TrangThai'] ?? json['status'],
      createdAt: _parseDateTime(json['createdAt']) ??
          _parseDateTime(json['NgayTao']) ??
          DateTime.now(),
      lastLogin: _parseDateTime(json['LanDangNhapCuoi']) ??
          _parseDateTime(json['lastLogin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'TenDangNhap': username,
      'email': email,
      'Email': email,
      'fullName': fullName,
      'HoTen': fullName,
      'avatar': avatar,
      'AnhDaiDien': avatar,
      'role': role,
      'VaiTro': role,
      'currentLevel': currentLevel,
      'TrinhDo': currentLevel,
      'phone': phone,
      'SoDienThoai': phone,
      'address': address,
      'DiaChi': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'NgaySinh': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'GioiTinh': gender,
      'status': status,
      'TrangThai': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatar,
    String? role,
    String? currentLevel,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      currentLevel: currentLevel ?? this.currentLevel,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
