import '../../reports/models/report.dart';
import 'admin_json.dart';

/// Một báo cáo ở màn quản trị: báo cáo kèm tên người gửi (server populate
/// người gửi vào `user_id`).
class AdminReport {
  const AdminReport({required this.report, required this.reporter});

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final user = json['user_id'];
    final names = user is Map ? [user['HoTen'], user['TenDangNhap'], user['Email']] : const [];
    return AdminReport(
      report: Report.fromJson(json),
      reporter: names
          .map((name) => '${name ?? ''}'.trim())
          .firstWhere((name) => name.isNotEmpty, orElse: () => 'Ẩn danh'),
    );
  }

  final Report report;
  final String reporter;
}

/// Số báo cáo theo trạng thái trên toàn hệ thống.
class AdminReportStats {
  const AdminReportStats({required this.total, required this.pending, required this.inProgress, required this.resolved});

  factory AdminReportStats.fromJson(Map<String, dynamic> json) => AdminReportStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        pending: groupCount(json['byStatus'], 'pending'),
        inProgress: groupCount(json['byStatus'], 'in_progress'),
        resolved: groupCount(json['byStatus'], 'resolved'),
      );

  final int total;
  final int pending;
  final int inProgress;
  final int resolved;
}
