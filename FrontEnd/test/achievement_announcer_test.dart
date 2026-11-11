import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/achievement_announcer.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/notification_provider.dart';
import 'package:apphoctiengnnhat/features/notifications/services/notification_service.dart';
import 'package:apphoctiengnnhat/features/notifications/widgets/achievement_toast_host.dart';

const _settle = Duration(milliseconds: 500);

AppNotification _badge(String id, {String name = 'Bước Đầu Tiên', int minute = 0}) => AppNotification(
      id: id,
      title: 'Huy hiệu mới: $name',
      message: 'Bạn đã hoàn thành "Học 7 ngày liên tiếp" và được cộng 100 XP.',
      type: NotificationType.achievement,
      isRead: false,
      createdAt: DateTime.utc(2026, 11, 9, 8, minute),
      data: {'achievement_id': 'a-$id', 'name': name, 'icon': '🔥', 'rarity': 'rare', 'xp': 100},
    );

/// Service giả: trả các huy hiệu chưa đọc (mới nhất trước, như API), ghi lại lời gọi.
class _FakeService extends NotificationService {
  final unread = <AppNotification>[];
  final requests = <String>[];
  final marked = <String>[];
  Completer<void>? gate;
  bool fail = false;
  int unreadCountCalls = 0;

  @override
  Future<NotificationPage> getNotifications({
    int page = 1,
    NotificationFilter status = NotificationFilter.all,
    NotificationType? type,
  }) async {
    requests.add('${status.name} ${type?.key}');
    await gate?.future;
    if (fail) throw ApiException('Mất kết nối máy chủ');
    final items = unread.where((row) => !marked.contains(row.id)).toList();
    return NotificationPage(items: items, page: 1, totalPages: 1, total: items.length);
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    marked.add(id);
    return unread.firstWhere((row) => row.id == id);
  }

  @override
  Future<int> unreadCount() async {
    unreadCountCalls++;
    return unread.where((row) => !marked.contains(row.id)).length;
  }
}

AchievementAnnouncer _announcer(_FakeService service) =>
    AchievementAnnouncer(service: service, listenToWrites: false, settle: _settle);

void main() {
  group('AchievementAnnouncer', () {
    test('hỏi huy hiệu chưa đọc và đưa ra theo thứ tự nhận, mỗi huy hiệu một lần', () async {
      final service = _FakeService()..unread.addAll([_badge('b2', minute: 2), _badge('b1', minute: 1)]);
      final announcer = _announcer(service);

      await announcer.check();
      expect(service.requests, ['unread ACHIEVEMENT']);
      expect(announcer.takePending().map((n) => n.id), ['b1', 'b2']);
      expect(announcer.takePending(), isEmpty, reason: 'lấy rồi thì hết');

      // Server vẫn trả hai huy hiệu đó (chưa kịp đánh dấu đã đọc): không đưa ra lần nữa.
      await announcer.check();
      expect(announcer.takePending(), isEmpty);
    });

    test('huy hiệu đã hiện được đánh dấu đã đọc trên server', () async {
      final service = _FakeService()..unread.addAll([_badge('b1'), _badge('b2')]);
      final announcer = _announcer(service);

      await announcer.check();
      await announcer.markShown(announcer.takePending());

      expect(service.marked, unorderedEquals(['b1', 'b2']));
    });

    test('lỗi khi hỏi thì im lặng; lần sau hỏi lại được', () async {
      final service = _FakeService()
        ..unread.add(_badge('b1'))
        ..fail = true;
      final announcer = _announcer(service);

      await announcer.check();
      expect(announcer.takePending(), isEmpty);

      service.fail = false;
      await announcer.check();
      expect(announcer.takePending().map((n) => n.id), ['b1']);
    });

    test('đăng xuất bỏ huy hiệu đang chờ và phản hồi về muộn', () async {
      final service = _FakeService()
        ..unread.add(_badge('b1'))
        ..gate = Completer<void>();
      final announcer = _announcer(service);

      final inFlight = announcer.check();
      announcer.clear();
      service.gate!.complete();
      await inFlight;

      expect(announcer.takePending(), isEmpty);
    });

    testWidgets('chỉ lệnh ghi hoạt động học làm app hỏi lại; ghi liên tiếp gộp thành một lần hỏi', (tester) async {
      final service = _FakeService();
      final announcer = _announcer(service);
      addTearDown(announcer.dispose);

      for (final endpoint in [
        '/lesson-progress/lesson/l1/update',
        '/lesson-progress/lesson/l1/complete',
        '/exercise/submit/e1',
        '/jlpt/j1/submit',
        '/srs/review',
        '/vocabulary/v1/mark-learned',
      ]) {
        announcer.onWrite('POST', endpoint);
      }
      await tester.pump(_settle);
      expect(service.requests, hasLength(1), reason: 'sáu lệnh ghi liền nhau chỉ hỏi một lần');

      for (final (method, endpoint) in [
        ('PUT', '/settings'),
        ('DELETE', '/vocabulary/v1/mark-learned'),
        ('POST', '/lesson-progress/lesson/l1/start'),
        ('POST', '/srs/items/v1/reset'),
        ('PUT', '/notifications/read/n1'),
        ('POST', '/vocabulary'),
      ]) {
        announcer.onWrite(method, endpoint);
      }
      await tester.pump(_settle);
      expect(service.requests, hasLength(1), reason: 'không lệnh nào ở trên cấp được huy hiệu');
    });

    testWidgets('đăng xuất huỷ lần hỏi đang hẹn', (tester) async {
      final service = _FakeService();
      final announcer = _announcer(service);
      addTearDown(announcer.dispose);

      announcer.onWrite('POST', '/srs/review');
      announcer.clear();
      await tester.pump(_settle * 2);

      expect(service.requests, isEmpty);
    });
  });

  group('ApiClient báo lệnh ghi', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('báo sau lệnh ghi thành công; không báo cho GET hay lệnh ghi lỗi', () async {
      final api = ApiClient();
      final writes = <String>[];
      void listener(String method, String endpoint) => writes.add('$method $endpoint');
      api.addWriteListener(listener);
      addTearDown(() => api.removeWriteListener(listener));

      await http.runWithClient(() async {
        await api.get('/lesson');
        await api.post('/srs/review', {});
        await api.put('/settings', {});
        await api.delete('/vocabulary/v1/mark-learned');
        await expectLater(api.post('/exercise/submit/e1', {}), throwsA(isA<ApiException>()));
      }, () => MockClient((request) async {
        final failed = request.url.path.endsWith('/exercise/submit/e1');
        return http.Response(jsonEncode(failed ? {'message': 'Sai dữ liệu'} : {'data': {}}), failed ? 400 : 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }));

      expect(writes, ['POST /srs/review', 'PUT /settings', 'DELETE /vocabulary/v1/mark-learned']);
    });

    test('một người nghe hỏng không làm lệnh ghi thành công bị coi là lỗi', () async {
      final api = ApiClient();
      void broken(String method, String endpoint) => throw StateError('hỏng');
      api.addWriteListener(broken);
      addTearDown(() => api.removeWriteListener(broken));
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      final response = await http.runWithClient(
        () => api.post('/srs/review', {}),
        () => MockClient((_) async => http.Response(jsonEncode({'data': 'ok'}), 200,
            headers: {'content-type': 'application/json; charset=utf-8'})),
      );

      expect(response['data'], 'ok');
      expect(reported.single.exception, isA<StateError>());
    });
  });

  group('AchievementToastHost', () {
    Future<(_FakeService, AchievementAnnouncer, List<String>)> pumpHost(WidgetTester tester) async {
      final service = _FakeService();
      final announcer = _announcer(service);
      final opened = <String>[];
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: announcer),
          ChangeNotifierProvider(create: (_) => NotificationProvider(service: service)),
        ],
        child: MaterialApp(
          builder: (context, child) => AchievementToastHost(
            onOpenAchievements: () => opened.add('/achievements'),
            child: child!,
          ),
          home: const Scaffold(body: Text('Đang học')),
        ),
      ));
      return (service, announcer, opened);
    }

    testWidgets('một huy hiệu mới: hiện tên, tiêu chí, nút Xem; rồi đánh dấu đã đọc', (tester) async {
      final (service, announcer, opened) = await pumpHost(tester);
      service.unread.add(_badge('b1'));

      await announcer.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Huy hiệu mới: Bước Đầu Tiên'), findsOneWidget);
      expect(find.text('Bạn đã hoàn thành "Học 7 ngày liên tiếp" và được cộng 100 XP.'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(service.marked, ['b1']);
      expect(service.unreadCountCalls, 1, reason: 'chấm trên chuông cập nhật theo');

      await tester.tap(find.text('Xem'));
      await tester.pump();
      expect(opened, ['/achievements']);
    });

    testWidgets('nhiều huy hiệu cùng lúc gộp thành một lời báo', (tester) async {
      final (service, announcer, _) = await pumpHost(tester);
      service.unread.addAll([_badge('b2', name: 'Khởi Động', minute: 2), _badge('b1', minute: 1)]);

      await announcer.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Bạn vừa nhận 2 huy hiệu mới'), findsOneWidget);
      expect(find.text('Bước Đầu Tiên, Khởi Động'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(service.marked, unorderedEquals(['b1', 'b2']));
    });

    testWidgets('không xếp hàng sau lời báo "đã lưu" của màn hình — huy hiệu hiện ngay', (tester) async {
      final (service, announcer, _) = await pumpHost(tester);
      final messenger = tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
      // Màn học vừa báo lưu thành công bằng SnackBar 4 giây của nó.
      messenger.showSnackBar(const SnackBar(content: Text('Đã đánh dấu là đã học.')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      service.unread.add(_badge('b1'));

      await announcer.check();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Huy hiệu mới: Bước Đầu Tiên'), findsOneWidget);
      expect(find.text('Đã đánh dấu là đã học.'), findsNothing);
    });
  });
}
