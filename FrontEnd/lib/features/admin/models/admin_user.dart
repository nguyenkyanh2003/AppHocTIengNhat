import 'admin_json.dart';

/// Bộ lọc nhanh của màn quản lý người dùng, dịch thẳng sang query của API.
enum AdminUserFilter {
  all('Tất cả'),
  active('Đang hoạt động', status: 'active'),
  admins('Quản trị viên', role: 'admin'),
  banned('Bị khoá', status: 'banned');

  const AdminUserFilter(this.label, {this.status, this.role});

  final String label;
  final String? status;
  final String? role;
}

/// Một tài khoản trong danh sách quản trị, đọc từ các trường tiếng Việt của `User`.
///
/// XP và chuỗi ngày là `total_xp`/`current_streak` server ghép từ streak thật.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.level,
    required this.totalXp,
    required this.streak,
    this.joinedAt,
    this.lastActiveAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['_id'] as String,
        username: json['TenDangNhap'] as String? ?? '',
        name: (json['HoTen'] as String? ?? '').trim(),
        email: json['Email'] as String? ?? '',
        role: json['VaiTro'] as String? ?? 'user',
        status: json['TrangThai'] as String? ?? 'active',
        level: json['TrinhDo'] as String? ?? 'N5',
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        streak: (json['current_streak'] as num?)?.toInt() ?? 0,
        joinedAt: adminDateOf(json['NgayTao']),
        lastActiveAt: adminDateOf(json['LanDangNhapCuoi']),
      );

  final String id;
  final String username;
  final String name;
  final String email;
  final String role;
  final String status;
  final String level;
  final int totalXp;
  final int streak;
  final DateTime? joinedAt;

  /// `null` khi chưa đăng nhập lần nào.
  final DateTime? lastActiveAt;

  bool get isAdmin => role == 'admin';
  bool get isBanned => status == 'banned';

  /// Họ tên; chưa đặt thì là tên đăng nhập.
  String get displayName => name.isNotEmpty ? name : username;
}

/// Số tài khoản theo vai trò và trạng thái, đếm trên toàn hệ thống — không
/// theo trang hay bộ lọc đang xem.
class AdminUserStats {
  const AdminUserStats({required this.total, required this.admins, required this.active, required this.banned});

  factory AdminUserStats.fromJson(Map<String, dynamic> json) => AdminUserStats(
        total: (json['totalUsers'] as num?)?.toInt() ?? 0,
        admins: groupCount(json['byRole'], 'admin'),
        active: groupCount(json['byStatus'], 'active'),
        banned: groupCount(json['byStatus'], 'banned'),
      );

  final int total;
  final int admins;
  final int active;
  final int banned;
}
