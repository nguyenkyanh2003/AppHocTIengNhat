import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/notification_provider.dart';
import 'package:apphoctiengnnhat/features/notifications/screens/notifications_screen.dart';
import 'package:apphoctiengnnhat/features/notifications/services/notification_service.dart';

AppNotification _notification(String id, {bool read = false, String? message}) => AppNotification(
      id: id,
      title: 'Tiêu đề $id',
      message: message ?? 'Nội dung $id',
      type: NotificationType.exam,
      isRead: read,
      createdAt: DateTime.now().toUtc(),
    );

/// Service giả lưu trong bộ nhớ (một trang là đủ cho màn hình).
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(this.rows);

  final List<AppNotification> rows;
  bool failList = false;

  @override
  Future<NotificationPage> getNotifications({
    int page = 1,
    NotificationFilter status = NotificationFilter.all,
    NotificationType? type,
  }) async {
    if (failList) throw ApiException('Mất kết nối máy chủ');
    final items = rows.where((row) => switch (status) {
          NotificationFilter.all => true,
          NotificationFilter.read => row.isRead,
          NotificationFilter.unread => !row.isRead,
        }).toList();
    return NotificationPage(items: items, page: 1, totalPages: items.isEmpty ? 0 : 1, total: items.length);
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final index = rows.indexWhere((row) => row.id == id);
    final row = rows[index];
    return rows[index] = AppNotification(id: row.id, title: row.title, message: row.message, type: row.type,
        isRead: true, readAt: DateTime.now().toUtc(), createdAt: row.createdAt);
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
  Future<int> unreadCount() async => rows.where((row) => !row.isRead).length;
}

Future<NotificationProvider> _pump(WidgetTester tester, _FakeNotificationService service) async {
  final provider = NotificationProvider(service: service);
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.lightTheme, home: const NotificationsScreen()),
  ));
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  testWidgets('thông báo đã đọc và chưa đọc đều có nút xoá', (tester) async {
    final service = _FakeNotificationService([_notification('a'), _notification('b', read: true)]);
    await _pump(tester, service);

    expect(find.byTooltip('Xoá thông báo'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Xoá thông báo').last);
    await tester.pumpAndSettle();

    expect(find.text('Tiêu đề b'), findsNothing);
    expect(service.rows.map((row) => row.id), ['a']);
  });

  testWidgets('chạm thông báo chưa đọc: mở nội dung đầy đủ và đánh dấu đã đọc', (tester) async {
    final longMessage = 'Lịch thi thử N4 ' * 20;
    final service = _FakeNotificationService([_notification('a', message: longMessage)]);
    final provider = await _pump(tester, service);
    expect(provider.unreadCount, 1);

    await tester.tap(find.text('Tiêu đề a'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text(longMessage)), findsOneWidget);
    expect(provider.unreadCount, 0);
    expect(service.rows.single.isRead, isTrue);
  });

  testWidgets('thông báo huy hiệu có biểu tượng huy hiệu và nút mở màn Thành tích', (tester) async {
    final service = _FakeNotificationService([
      AppNotification(
        id: 'b1',
        title: 'Huy hiệu mới: Bước Đầu Tiên',
        message: 'Bạn đã hoàn thành "Học 7 ngày liên tiếp" và được cộng 100 XP.',
        type: NotificationType.achievement,
        isRead: false,
        createdAt: DateTime.now().toUtc(),
        data: const {'name': 'Bước Đầu Tiên', 'icon': '🔥'},
      ),
    ]);
    final provider = NotificationProvider(service: service);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/achievements', builder: (context, state) => const Text('Màn Thành tích')),
    ]);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Thành tích · Vừa xong'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);

    await tester.tap(find.text('Huy hiệu mới: Bước Đầu Tiên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem thành tích'));
    await tester.pumpAndSettle();

    expect(find.text('Màn Thành tích'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.rows.single.isRead, isTrue);
  });

  testWidgets('nút "Đánh dấu tất cả đã đọc" chỉ bật khi còn thông báo chưa đọc', (tester) async {
    final service = _FakeNotificationService([_notification('a'), _notification('b')]);
    final provider = await _pump(tester, service);
    expect(find.text('Chưa đọc (2)'), findsOneWidget);

    await tester.tap(find.byTooltip('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();

    expect(provider.unreadCount, 0);
    expect(service.rows.every((row) => row.isRead), isTrue);
    final button = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.done_all));
    expect(button.onPressed, isNull);
  });

  testWidgets('lỗi tải hiện lỗi kèm thử lại, không giả làm "không có thông báo"', (tester) async {
    final service = _FakeNotificationService([_notification('a')])..failList = true;
    await _pump(tester, service);

    expect(find.text('Mất kết nối máy chủ'), findsOneWidget);
    expect(find.text('Chưa có thông báo nào'), findsNothing);

    service.failList = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tiêu đề a'), findsOneWidget);
  });

  testWidgets('bộ lọc không có gì thì báo rỗng theo đúng bộ lọc', (tester) async {
    await _pump(tester, _FakeNotificationService([_notification('a', read: true)]));

    await tester.tap(find.text('Chưa đọc'));
    await tester.pumpAndSettle();

    expect(find.text('Không có thông báo chưa đọc'), findsOneWidget);
  });
}
