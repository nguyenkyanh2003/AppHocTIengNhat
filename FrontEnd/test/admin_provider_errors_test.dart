import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_provider.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';

/// Thống kê và người dùng tải được; báo cáo không tải được; khoá tài khoản lỗi.
class _FakeAdminService extends AdminService {
  @override
  Future<Map<String, dynamic>> getDashboardStats() async => {'users': 3};

  @override
  Future<List<dynamic>> getAllUsers({int page = 1, int limit = 20, String? search, String? status, String? role}) async => [
        {'_id': 'u1', 'name': 'An'},
      ];

  @override
  Future<Map<String, dynamic>> getUserStats() async => {};

  @override
  Future<List<dynamic>> getReports({int page = 1, int limit = 20, String? status, String? type}) async =>
      throw ApiException('Không tải được báo cáo');

  @override
  Future<Map<String, dynamic>> banUser(String userId) async => throw ApiException('Không khoá được');
}

void main() {
  late AdminProvider provider;

  setUp(() => provider = AdminProvider(adminService: _FakeAdminService()));

  test('mỗi khu quản trị có lỗi tải riêng: báo cáo lỗi không làm trang tổng quan hay người dùng báo lỗi', () async {
    await provider.loadDashboardStats();
    await provider.loadUsers();
    await provider.loadReports();

    expect(provider.loadErrorOf(AdminSection.reports), 'Không tải được báo cáo');
    expect(provider.loadErrorOf(AdminSection.stats), isNull);
    expect(provider.loadErrorOf(AdminSection.users), isNull);
  });

  test('thao tác lỗi chỉ báo qua `error` cho SnackBar, không biến danh sách đang có thành màn lỗi', () async {
    await provider.loadUsers();

    expect(await provider.banUser('u1'), isFalse);
    expect(provider.error, 'Không khoá được');
    expect(provider.loadErrorOf(AdminSection.users), isNull);
    expect(provider.users, isNotEmpty);
  });

  test('tải lại thành công thì xoá lỗi tải cũ của chính khu đó', () async {
    await provider.loadReports();
    provider.clearLoadError(AdminSection.reports);
    expect(provider.loadErrorOf(AdminSection.reports), isNull);
  });
}
