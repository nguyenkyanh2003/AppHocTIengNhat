import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';
import 'package:apphoctiengnnhat/features/notifications/services/notification_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _dto = {
  'id': 'n1',
  'title': 'Lịch thi',
  'message': 'Thi thử N4 vào thứ Bảy',
  'type': 'EXAM',
  'data': {},
  'is_read': false,
  'read_at': null,
  'created_at': '2026-11-04T08:00:00.000Z',
};

void main() {
  test('đọc trang thông báo theo hợp đồng mới, gửi đúng bộ lọc', () async {
    final requests = <http.Request>[];
    final page = await http.runWithClient(
      () => NotificationService().getNotifications(page: 2, status: NotificationFilter.unread),
      () => MockClient((request) async {
        requests.add(request);
        return _json({'data': [_dto], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(requests.single.url.path, '/api/notifications');
    expect(requests.single.url.queryParameters, {'page': '2', 'limit': '20', 'status': 'unread'});
    expect((page.page, page.totalPages, page.total), (2, 2, 21));

    final item = page.items.single;
    expect((item.id, item.title, item.message), ('n1', 'Lịch thi', 'Thi thử N4 vào thứ Bảy'));
    expect(item.type, NotificationType.exam);
    expect(item.isRead, isFalse);
    expect(item.readAt, isNull);
    expect(item.createdAt, DateTime.utc(2026, 11, 4, 8));
  });

  test('đọc một, đọc tất cả, xoá và đếm gọi đúng route', () async {
    final requests = <http.Request>[];
    late final AppNotification read;
    late final int updated;
    late final int unread;

    await http.runWithClient(() async {
      final service = NotificationService();
      read = await service.markAsRead('n1');
      updated = await service.markAllAsRead();
      await service.deleteNotification('n1');
      unread = await service.unreadCount();
    }, () => MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/read/n1')) return _json({'data': {..._dto, 'is_read': true, 'read_at': '2026-11-04T09:00:00.000Z'}});
      if (path.endsWith('/read-all')) return _json({'data': {'updated': 2}});
      if (path.endsWith('/count/unread')) return _json({'data': {'unread_count': 3}});
      return _json({'data': {'deleted': true}});
    }));

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'PUT /api/notifications/read/n1',
      'PUT /api/notifications/read-all',
      'DELETE /api/notifications/n1',
      'GET /api/notifications/count/unread',
    ]);
    expect(read.isRead, isTrue);
    expect(read.readAt, DateTime.utc(2026, 11, 4, 9));
    expect(updated, 2);
    expect(unread, 3);
  });

  test('lỗi khi đếm chưa đọc được ném ra, không biến thành 0', () async {
    await http.runWithClient(() async {
      await expectLater(NotificationService().unreadCount(), throwsA(anything));
    }, () => MockClient((_) async => _json({'message': 'Lỗi máy chủ'}, 500)));
  });

  test('loại lạ hiểu là thông báo hệ thống', () {
    expect(AppNotification.fromJson({..._dto, 'type': 'PROMOTION'}).type, NotificationType.system);
  });

  test('thông báo huy hiệu đọc được loại và dữ liệu huy hiệu kèm theo', () {
    final badge = AppNotification.fromJson({
      ..._dto,
      'type': 'ACHIEVEMENT',
      'data': {'achievement_id': 'a1', 'name': 'Bước Đầu Tiên', 'icon': '🔥', 'rarity': 'rare', 'xp': 100},
    });

    expect(badge.type, NotificationType.achievement);
    expect(badge.badgeName, 'Bước Đầu Tiên');
    expect(badge.badgeIcon, '🔥');
    expect(AppNotification.fromJson(_dto).badgeIcon, isNull);
    expect(AppNotification.fromJson({..._dto, 'data': null}).data, isEmpty);
  });

  test('lọc danh sách theo loại khi cần, không gửi loại thì không lọc', () async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      final service = NotificationService();
      await service.getNotifications(status: NotificationFilter.unread, type: NotificationType.achievement);
      await service.getNotifications();
    }, () => MockClient((request) async {
      requests.add(request);
      return _json({'data': [], 'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0});
    }));

    expect(requests[0].url.queryParameters, {'page': '1', 'limit': '20', 'status': 'unread', 'type': 'ACHIEVEMENT'});
    expect(requests[1].url.queryParameters.containsKey('type'), isFalse);
  });

  test('admin chỉ chọn được loại gửi tay — thông báo huy hiệu chỉ server tạo', () {
    expect(NotificationType.sendable, [NotificationType.system, NotificationType.lesson, NotificationType.exam]);
    expect(NotificationType.sendable, isNot(contains(NotificationType.achievement)));
  });
}
