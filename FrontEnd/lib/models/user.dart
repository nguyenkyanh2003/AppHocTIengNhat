class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatar;
  final String role;
  final String? currentLevel;
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
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['TenDangNhap'] ?? json['username'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      fullName: json['HoTen'] ?? json['fullName'],
      avatar: json['AnhDaiDien'] ?? json['avatar'],
      role: json['VaiTro'] ?? json['role'] ?? 'user',
      currentLevel: json['TrinhDo'] ?? json['currentLevel'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['NgayTao'] != null
              ? DateTime.parse(json['NgayTao'])
              : DateTime.now()),
      lastLogin: json['LanDangNhapCuoi'] != null
          ? DateTime.parse(json['LanDangNhapCuoi'])
          : (json['lastLogin'] != null
              ? DateTime.parse(json['lastLogin'])
              : null),
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
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}