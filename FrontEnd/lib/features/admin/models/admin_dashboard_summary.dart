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

  factory AdminDashboardSummary.fromStats(Map<String, dynamic> stats) {
    final users = _map(stats['users']);
    final lessons = _map(stats['lessons']);
    final reports = _map(stats['reports']);
    final analytics = _map(stats['analytics']);

    final activities = <AdminActivity>[
      for (final raw in _list(users['recentUsers']))
        if (_date(_map(raw)['NgayTao'] ?? _map(raw)['createdAt'])
            case final at?)
          AdminActivity(
            kind: AdminActivityKind.newUser,
            title: 'Người dùng mới đăng ký',
            subtitle: (_map(raw)['HoTen'] ?? _map(raw)['TenDangNhap'] ?? '')
                .toString(),
            at: at,
          ),
      for (final raw in _list(reports['recentReports']))
        if (_date(_map(raw)['createdAt']) case final at?)
          AdminActivity(
            kind: AdminActivityKind.newReport,
            title: 'Báo cáo mới',
            subtitle: (_map(raw)['title'] ?? '').toString(),
            at: at,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return AdminDashboardSummary(
      totalUsers: _int(users['totalUsers']),
      totalLessons: _int(lessons['totalLessons']),
      pendingReports: _countOf(reports['byStatus'], 'pending'),
      activeToday: _int(_map(analytics['metrics'])['active_today']),
      activities: activities.take(6).toList(),
    );
  }

  final int totalUsers;
  final int totalLessons;
  final int pendingReports;
  final int activeToday;
  final List<AdminActivity> activities;

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  static int _int(dynamic value) => value is num ? value.toInt() : 0;

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  /// Đọc số lượng của một nhóm từ kết quả `$group` (`[{ _id, count }]`).
  static int _countOf(dynamic rows, String id) {
    for (final row in _list(rows)) {
      final map = _map(row);
      if (map['_id'] == id) return _int(map['count']);
    }
    return 0;
  }
}
