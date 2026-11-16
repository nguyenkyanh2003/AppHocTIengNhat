import 'admin_json.dart';

/// Một sự kiện gần đây trên bảng điều khiển quản trị.
class AdminActivity {
  const AdminActivity({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final AdminActivityKind kind;
  final String title;
  final String subtitle;
  final DateTime at;
}

enum AdminActivityKind { newUser, newReport }

/// Số liệu tổng quan, ghép từ các API thống kê của quản trị.
///
/// Thiếu số thì là 0 thay vì một con số mẫu: bảng điều khiển không được hiện số
/// không có thật.
class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.totalLessons,
    required this.pendingReports,
    required this.activeToday,
    required this.activities,
  });

  /// [stats] gom phần `data` của bốn API: `users`, `lessons`, `reports`, `analytics`.
  factory AdminDashboardSummary.fromStats(Map<String, dynamic> stats) {
    final users = _map(stats['users']);
    final lessons = _map(stats['lessons']);
    final reports = _map(stats['reports']);
    final analytics = _map(stats['analytics']);

    final activities = <AdminActivity>[
      for (final user in _list(users['recentUsers']).map(_map))
        if (adminDateOf(user['NgayTao'] ?? user['createdAt']) case final at?)
          AdminActivity(
            kind: AdminActivityKind.newUser,
            title: 'Người dùng mới đăng ký',
            subtitle: '${user['HoTen'] ?? user['TenDangNhap'] ?? ''}',
            at: at,
          ),
      for (final report in _list(reports['recentReports']).map(_map))
        if (adminDateOf(report['createdAt']) case final at?)
          AdminActivity(
            kind: AdminActivityKind.newReport,
            title: 'Báo cáo mới',
            subtitle: '${report['title'] ?? ''}',
            at: at,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return AdminDashboardSummary(
      totalUsers: _int(users['totalUsers']),
      totalLessons: _int(lessons['totalLessons']),
      pendingReports: groupCount(reports['byStatus'], 'pending'),
      activeToday: _int(_map(analytics['metrics'])['active_today']),
      activities: activities.take(6).toList(),
    );
  }

  final int totalUsers;
  final int totalLessons;
  final int pendingReports;
  final int activeToday;
  final List<AdminActivity> activities;

  static Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Object?> _list(Object? value) => value is List ? value : const [];

  static int _int(Object? value) => value is num ? value.toInt() : 0;
}
