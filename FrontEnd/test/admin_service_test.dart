import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/features/admin/models/admin_content_type.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_user.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

/// Chạy [action] với server giả trả [reply] theo đường dẫn; ghi lại mọi request.
Future<(T, List<http.Request>)> _run<T>(Future<T> Function(AdminService service) action, Object Function(Uri url) reply) async {
  final requests = <http.Request>[];
  final result = await http.runWithClient(
    () => action(AdminService()),
    () => MockClient((request) async {
      requests.add(request);
      return _json(reply(request.url));
    }),
  );
  return (result, requests);
}

Map<String, Object?> _paged(List<Object?> items, {int page = 1, int totalPages = 1}) =>
    {'data': items, 'page': page, 'limit': 20, 'total': items.length, 'totalPages': totalPages};

void main() {
  test('người dùng: bộ lọc thành query, trường tiếng Việt thành model', () async {
    final (page, requests) = await _run(
      (service) => service.users(page: 2, search: 'lan', filter: AdminUserFilter.banned),
      (_) => _paged([
        {
          '_id': 'u1',
          'TenDangNhap': 'lan',
          'HoTen': ' Lê Lan ',
          'Email': 'lan@example.invalid',
          'VaiTro': 'admin',
          'TrangThai': 'banned',
          'DiemTichLuy': 120,
          'StreakHienTai': 3,
          'NgayTao': '2026-11-05 14:00:00',
        },
      ], page: 2, totalPages: 3),
    );

    expect(requests.single.url.path, '/api/users/admin/users');
    expect(requests.single.url.queryParameters, {'page': '2', 'limit': '20', 'search': 'lan', 'status': 'banned'});
    final user = page.items.single;
    expect((user.displayName, user.isAdmin, user.isBanned, user.totalXp), ('Lê Lan', true, true, 120));
    expect(user.joinedAt, DateTime(2026, 11, 5, 14));
    expect(user.lastActiveAt, isNull);
    expect(page.hasMore, isTrue);
  });

  test('số đếm người dùng đọc kết quả nhóm theo vai trò và trạng thái', () async {
    final (stats, _) = await _run(
      (service) => service.userStats(),
      (_) => {
        'data': {
          'totalUsers': 9,
          'byRole': [
            {'_id': 'admin', 'count': 2},
          ],
          'byStatus': [
            {'_id': 'active', 'count': 7},
            {'_id': 'banned', 'count': 2},
          ],
        },
      },
    );

    expect((stats.total, stats.admins, stats.active, stats.banned), (9, 2, 7, 2));
  });

  test('tổng quan ghép phần data của bốn API thống kê', () async {
    final (summary, requests) = await _run(
      (service) => service.dashboard(),
      (url) => {
        'data': switch (url.path) {
          '/api/users/admin/stats' => {'totalUsers': 12},
          '/api/lesson/stats/overview' => {'totalLessons': 40},
          '/api/report/admin/stats' => {
              'byStatus': [
                {'_id': 'pending', 'count': 3},
              ],
            },
          _ => {
              'metrics': {'active_today': 5},
            },
        },
      },
    );

    expect(requests, hasLength(4));
    expect((summary.totalUsers, summary.totalLessons, summary.pendingReports, summary.activeToday), (12, 40, 3, 5));
  });

  test('phân tích theo kỳ đọc chuỗi ngày và phân bố trình độ', () async {
    final (analytics, requests) = await _run(
      (service) => service.analytics(period: '30d'),
      (_) => {
        'data': {
          'labels': ['2026-11-04', '2026-11-05'],
          'metrics': {'total_users': 8, 'study_minutes': 42},
          'daily_active_users': [1, 2],
          'level_distribution': {'N5': 6, 'Chưa đặt': 2},
        },
      },
    );

    expect(requests.single.url.queryParameters, {'period': '30d'});
    expect(analytics.labels, ['2026-11-04', '2026-11-05']);
    expect((analytics.totalUsers, analytics.studyMinutes, analytics.activeToday), (8, 42, 0));
    expect(analytics.dailyActiveUsers, [1, 2]);
    expect(analytics.newRegistrations, isEmpty);
    expect(analytics.levelDistribution, {'N5': 6, 'Chưa đặt': 2});
  });

  test('nội dung đi theo đường dẫn của từng loại', () async {
    final (_, requests) = await _run((service) async {
      await service.content(AdminContentType.lessons, page: 3);
      await service.deleteContent(AdminContentType.kanji, 'k1');
      await service.updateContent(AdminContentType.grammar, 'g1', {'title': 'は'});
    }, (url) => url.path.startsWith('/api/lesson') ? _paged(const []) : {'data': {}});

    expect(requests.map((r) => '${r.method} ${r.url.path} ${r.url.query}'.trim()), [
      'GET /api/lesson page=3&limit=50',
      'DELETE /api/kanji/k1',
      'PUT /api/grammar/g1',
    ]);
  });

  test('báo cáo: người gửi lấy từ document populate; đổi trạng thái không gửi phản hồi rỗng', () async {
    final (page, requests) = await _run((service) async {
      final page = await service.reports(status: 'pending');
      await service.updateReport('r1', status: 'resolved');
      return page;
    }, (url) => url.path.endsWith('/all')
        ? _paged([
            {
              '_id': 'r1',
              'title': 'Sai nghĩa',
              'description': 'Từ 学生',
              'createdAt': '2026-11-05 14:00:00',
              'user_id': {'TenDangNhap': 'lan', 'Email': 'lan@example.invalid'},
            },
          ])
        : {'data': {}});

    expect(page.items.single.reporter, 'lan');
    expect(requests.first.url.queryParameters['status'], 'pending');
    expect(jsonDecode(requests.last.body), {'status': 'resolved'});
  });

  test('giao dịch: tên người mua lấy từ document populate, không phải khoá tiếng Anh', () async {
    final (page, _) = await _run(
      (service) => service.transactions(),
      (_) => _paged([
        {
          '_id': 't1',
          'user': {'HoTen': 'Lê Lan', 'Email': 'lan@example.invalid'},
          'type': 'SUBSCRIPTION',
          'amount': 99000,
          'status': 'pending',
          'package_id': 'premium_month',
        },
      ]),
    );

    final tx = page.items.single;
    expect((tx.userName, tx.userEmail, tx.title, tx.isOpen), ('Lê Lan', 'lan@example.invalid', 'premium_month', true));
  });

  test('bài học để gán cho Excel đọc hết mọi trang', () async {
    final (lessons, requests) = await _run(
      (service) => service.lessonOptions(),
      (url) {
        final page = int.parse(url.queryParameters['page']!);
        return _paged([
          {'_id': 'l$page', 'title': 'Bài $page', 'level': 'N5'},
        ], page: page, totalPages: 2);
      },
    );

    expect(lessons.map((lesson) => lesson.id), ['l1', 'l2']);
    expect(requests.map((r) => r.url.queryParameters['limit']).toSet(), {'100'});
  });
}
