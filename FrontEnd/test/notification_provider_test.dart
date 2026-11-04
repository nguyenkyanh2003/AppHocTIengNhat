import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/notification_provider.dart';
import 'package:apphoctiengnnhat/features/notifications/services/notification_service.dart';

AppNotification _notification(int index, {bool read = false}) => AppNotification(
      id: 'n$index',
      title: 'Thông báo $index',
      message: 'Nội dung $index',
      type: NotificationType.system,
      isRead: read,
      createdAt: DateTime.utc(2026, 11, 1).add(Duration(minutes: index)),
    );

/// Service giả lưu trong bộ nhớ, phân trang và lọc như API thật.
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(this.rows);

  final List<AppNotification> rows;
  final gates = <NotificationFilter, Completer<void>>{};
  final calls = <String>[];
  bool failList = false;
  bool failCount = false;
  bool failMutation = false;

  @override
  Future<NotificationPage> getNotifications({int page = 1, NotificationFilter status = NotificationFilter.all}) async {
    calls.add('list $page ${status.name}');
    await gates[status]?.future;
    if (failList) throw ApiException('Mất kết nối máy chủ');
    final matched = rows.where((row) => switch (status) {
          NotificationFilter.all => true,
          NotificationFilter.read => row.isRead,
          NotificationFilter.unread => !row.isRead,
        }).toList();
    const size = NotificationService.pageSize;
    return NotificationPage(
      items: matched.skip((page - 1) * size).take(size).toList(),
      page: page,
      totalPages: (matched.length / size).ceil(),
      total: matched.length,
    );
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    if (failMutation) throw ApiException('Không lưu được.');
    final index = rows.indexWhere((row) => row.id == id);
    final row = rows[index];
    rows[index] = AppNotification(id: row.id, title: row.title, message: row.message, type: row.type,
        isRead: true, readAt: DateTime.utc(2026, 11, 4), createdAt: row.createdAt);
    return rows[index];
  }

  @override
  Future<int> markAllAsRead() async {
    final unread = rows.where((row) => !row.isRead).map((row) => row.id).toList();
    for (final id in unread) {
      await markAsRead(id);
    }
    return unread.length;
  }

  @override
  Future<void> deleteNotification(String id) async => rows.removeWhere((row) => row.id == id);

  @override
  Future<int> unreadCount() async {
    if (failCount) throw ApiException('Lỗi máy chủ');
    return rows.where((row) => !row.isRead).length;
  }
}

List<String> _ids(NotificationProvider provider) =>
    provider.page.valueOrNull?.items.map((item) => item.id).toList() ?? const [];

void main() {
  test('tải trang đầu kèm số chưa đọc', () async {
    final service = _FakeNotificationService([_notification(2), _notification(1, read: true)]);
    final provider = NotificationProvider(service: service);

    await Future.wait([provider.load(), provider.refreshUnreadCount()]);

    expect(_ids(provider), ['n2', 'n1']);
    expect(provider.unreadCount, 1);
  });

  test('lỗi tải hiện thành lỗi, không thành danh sách rỗng; thử lại được', () async {
    final service = _FakeNotificationService([_notification(1)])..failList = true;
    final provider = NotificationProvider(service: service);

    await provider.load();
    expect(provider.page.errorOrNull, 'Mất kết nối máy chủ');

    service.failList = false;
    await provider.load();
    expect(_ids(provider), ['n1']);
  });

  test('đổi bộ lọc: phản hồi của bộ lọc cũ về muộn bị bỏ', () async {
    final service = _FakeNotificationService([_notification(2), _notification(1, read: true)]);
    final provider = NotificationProvider(service: service);
    final slowAll = service.gates[NotificationFilter.all] = Completer<void>();

    final first = provider.load();
    await provider.load(filter: NotificationFilter.unread);
    slowAll.complete();
    await first;

    expect(provider.filter, NotificationFilter.unread);
    expect(_ids(provider), ['n2']);
  });

  test('đọc một thông báo: danh sách và bộ đếm cùng cập nhật', () async {
    final service = _FakeNotificationService([_notification(2), _notification(1)]);
    final provider = NotificationProvider(service: service);
    await Future.wait([provider.load(filter: NotificationFilter.unread), provider.refreshUnreadCount()]);

    await provider.markAsRead(provider.page.valueOrNull!.items.first);

    expect(_ids(provider), ['n1'], reason: 'đang lọc chưa đọc thì thông báo vừa đọc rời danh sách');
    expect(provider.unreadCount, 1);
  });

  test('đánh dấu tất cả đã đọc đưa bộ đếm về 0', () async {
    final service = _FakeNotificationService([_notification(2), _notification(1)]);
    final provider = NotificationProvider(service: service);
    await Future.wait([provider.load(), provider.refreshUnreadCount()]);

    await provider.markAllAsRead();

    expect(provider.unreadCount, 0);
    expect(provider.page.valueOrNull!.items.every((item) => item.isRead), isTrue);
  });

  test('xoá được cả thông báo đã đọc; xoá hết trang cuối thì lùi một trang', () async {
    final rows = [for (var i = 21; i >= 1; i--) _notification(i, read: i == 1)];
    final service = _FakeNotificationService(rows);
    final provider = NotificationProvider(service: service);
    await provider.load(page: 2);
    expect(_ids(provider), ['n1']);

    await provider.delete(provider.page.valueOrNull!.items.single);

    expect(provider.currentPage, 1);
    expect(_ids(provider), hasLength(20));
    expect(rows.any((row) => row.id == 'n1'), isFalse);
  });

  test('lỗi khi đếm giữ số đã biết, không về 0', () async {
    final service = _FakeNotificationService([_notification(2), _notification(1)]);
    final provider = NotificationProvider(service: service);
    await provider.refreshUnreadCount();

    service.failCount = true;
    await provider.refreshUnreadCount();

    expect(provider.unreadCount, 2);
  });

  test('thao tác lỗi báo qua thông điệp, danh sách vẫn giữ', () async {
    final service = _FakeNotificationService([_notification(1)]);
    final provider = NotificationProvider(service: service);
    await provider.load();

    service.failMutation = true;
    await provider.markAsRead(provider.page.valueOrNull!.items.single);

    expect(provider.consumeMessage(), 'Không lưu được.');
    expect(_ids(provider), ['n1']);
  });

  test('đăng xuất xoá sạch dữ liệu; phản hồi đang chờ của tài khoản cũ bị bỏ', () async {
    final service = _FakeNotificationService([_notification(1)]);
    final provider = NotificationProvider(service: service);
    await provider.refreshUnreadCount();
    final slow = service.gates[NotificationFilter.all] = Completer<void>();

    final pending = provider.load();
    provider.clear();
    slow.complete();
    await pending;

    expect(provider.page, isA<ViewIdle<NotificationPage>>());
    expect(provider.unreadCount, 0);
    expect(provider.filter, NotificationFilter.all);
  });
}
