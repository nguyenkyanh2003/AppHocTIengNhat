import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_report.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_user.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_reports_provider.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_users_provider.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';

Paged<T> _page<T>(List<T> items) => Paged(items: items, page: 1, limit: 20, total: items.length, totalPages: 1);

AdminUser _user(String id, {String status = 'active'}) =>
    AdminUser.fromJson({'_id': id, 'HoTen': 'Người $id', 'TrangThai': status});

AdminReport _report(String id) => AdminReport.fromJson({
      '_id': id,
      'title': 'Báo cáo $id',
      'description': 'Mô tả',
      'createdAt': '2026-11-05T07:00:00.000Z',
    });

/// Service giả ghi lại tham số mỗi lần gọi; lỗi bật theo từng phần.
class _FakeAdminService extends AdminService {
  final calls = <String>[];
  List<AdminUser> userList = [_user('u1')];
  Object? statsError;
  Object? writeError;

  @override
  Future<Paged<AdminUser>> users({int page = 1, String? search, AdminUserFilter filter = AdminUserFilter.all}) async {
    calls.add('users page=$page search=$search status=${filter.status} role=${filter.role}');
    return _page(userList);
  }

  @override
  Future<AdminUserStats> userStats() async {
    calls.add('userStats');
    if (statsError != null) throw statsError!;
    return const AdminUserStats(total: 9, admins: 2, active: 6, banned: 1);
  }

  @override
  Future<AdminUser> updateUser(String id, {String? role, String? status}) async {
    calls.add('updateUser $id role=$role status=$status');
    if (writeError != null) throw writeError!;
    return _user(id, status: status ?? 'active');
  }

  @override
  Future<int> broadcastNotification({required String title, required String message, required NotificationType type}) async =>
      12;

  @override
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    if (writeError != null) throw writeError!;
  }

  @override
  Future<Paged<AdminReport>> reports({int page = 1, String? status, String? type}) async {
    calls.add('reports status=$status type=$type');
    return _page([_report('r1')]);
  }

  @override
  Future<AdminReportStats> reportStats() async {
    calls.add('reportStats');
    if (statsError != null) throw statsError!;
    return const AdminReportStats(total: 1, pending: 1, inProgress: 0, resolved: 0);
  }

  @override
  Future<void> updateReport(String id, {required String status, String? response}) async {
    calls.add('updateReport $id status=$status response=$response');
    if (writeError != null) throw writeError!;
  }
}

void main() {
  group('người dùng', () {
    test('số đếm lỗi không làm danh sách lỗi theo', () async {
      final service = _FakeAdminService()..statsError = ApiException('Không tải được số liệu');
      final provider = AdminUsersProvider(service: service);

      await provider.load();

      expect(provider.users.valueOrNull?.single.id, 'u1');
      expect(provider.stats.errorOrNull, 'Không tải được số liệu');
    });

    test('bộ lọc và từ khoá đi thẳng xuống API, không lọc trên trang đã tải', () async {
      final service = _FakeAdminService();
      final provider = AdminUsersProvider(service: service);

      await provider.load();
      await provider.selectFilter(AdminUserFilter.banned);
      await provider.searchUsers('  lan ');
      await provider.selectFilter(AdminUserFilter.admins);

      expect(service.calls.where((call) => call.startsWith('users')), [
        'users page=1 search=null status=null role=null',
        'users page=1 search=null status=banned role=null',
        'users page=1 search=lan status=banned role=null',
        'users page=1 search=lan status=null role=admin',
      ]);
    });

    test('khoá thành công thì tải lại danh sách và số đếm theo đúng bộ lọc', () async {
      final service = _FakeAdminService();
      final provider = AdminUsersProvider(service: service);
      await provider.load();
      service.calls.clear();

      expect(await provider.setBanned(_user('u1'), true), isNull);

      expect(service.calls, [
        'updateUser u1 role=null status=banned',
        'users page=1 search=null status=null role=null',
        'userStats',
      ]);
    });

    test('thao tác lỗi trả câu báo lỗi, danh sách đang có giữ nguyên và không tải lại', () async {
      final service = _FakeAdminService()..writeError = ApiException('Không đổi được vai trò.');
      final provider = AdminUsersProvider(service: service);
      await provider.load();
      service.calls.clear();

      expect(await provider.setAdmin(_user('u1'), false), 'Không đổi được vai trò.');

      expect(service.calls, ['updateUser u1 role=user status=null']);
      expect(provider.users.valueOrNull, hasLength(1));
    });

    test('gửi cho tất cả trả số người nhận; gửi một người lỗi thì là failure đọc được', () async {
      final service = _FakeAdminService()..writeError = ApiException('Không tìm thấy người nhận.');
      final provider = AdminUsersProvider(service: service);

      final all = await provider.sendNotification(title: 't', message: 'm', type: NotificationType.system);
      final one = await provider.sendNotification(user: _user('u9'), title: 't', message: 'm', type: NotificationType.system);

      expect(all.valueOrNull, 12);
      expect(one.errorOrNull, 'Không tìm thấy người nhận.');
    });
  });

  group('báo cáo', () {
    test('lọc trạng thái và loại đi xuống API; số đếm lỗi không làm danh sách lỗi', () async {
      final service = _FakeAdminService()..statsError = ApiException('Hỏng');
      final provider = AdminReportsProvider(service: service);

      await provider.load();
      await provider.selectStatus('pending');
      await provider.selectType('bug');

      expect(provider.reports.valueOrNull?.single.report.id, 'r1');
      expect(provider.stats.errorOrNull, 'Hỏng');
      expect(service.calls.where((call) => call.startsWith('reports')), [
        'reports status=null type=null',
        'reports status=pending type=null',
        'reports status=pending type=bug',
      ]);
    });

    test('phản hồi chuyển báo cáo sang đang xử lý; đổi trạng thái không xoá phản hồi cũ', () async {
      final service = _FakeAdminService();
      final provider = AdminReportsProvider(service: service);
      final report = _report('r1');

      expect(await provider.respond(report, 'Đã sửa'), isNull);
      expect(await provider.setStatus(report, 'resolved'), isNull);

      expect(service.calls.where((call) => call.startsWith('updateReport')), [
        'updateReport r1 status=in_progress response=Đã sửa',
        'updateReport r1 status=resolved response=null',
      ]);
    });
  });
}
