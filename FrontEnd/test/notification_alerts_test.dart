import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/notification_alerts.dart';
import 'package:apphoctiengnnhat/features/notifications/providers/notification_provider.dart';
import 'package:apphoctiengnnhat/features/notifications/services/notification_service.dart';
import 'package:apphoctiengnnhat/features/notifications/widgets/notification_alert_host.dart';
import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/providers/settings_provider.dart';
import 'package:apphoctiengnnhat/features/settings/services/alert_feedback.dart';
import 'package:apphoctiengnnhat/features/settings/services/settings_service.dart';
import 'package:apphoctiengnnhat/shared/models/user.dart';

AppNotification _notice(String id, {NotificationType type = NotificationType.system, String? title}) => AppNotification(
      id: id,
      title: title ?? 'Thông báo $id',
      message: 'Nội dung $id',
      type: type,
      isRead: false,
      createdAt: DateTime.utc(2026, 11, 23),
    );

/// Server giả: danh sách chưa đọc, mới nhất trước.
class _FakeService extends NotificationService {
  final unread = <AppNotification>[];
  int fetches = 0;
  int unreadCountCalls = 0;
  bool offline = false;

  /// Phản hồi treo chờ test thả ra.
  Completer<void>? hold;

  @override
  Future<NotificationPage> getNotifications({
    int page = 1,
    NotificationFilter status = NotificationFilter.all,
    NotificationType? type,
  }) async {
    fetches++;
    final items = [...unread.reversed];
    await hold?.future;
    if (offline) throw ApiException('Mất kết nối');
    return NotificationPage(items: items, page: 1, total: items.length, totalPages: 1);
  }

  @override
  Future<int> unreadCount() async {
    unreadCountCalls++;
    return unread.length;
  }
}

void main() {
  group('NotificationAlerts', () {
    late _FakeService service;
    late NotificationAlerts alerts;

    setUp(() {
      service = _FakeService();
      alerts = NotificationAlerts(service: service, interval: const Duration(minutes: 1));
    });

    tearDown(() => alerts.dispose());

    test('lần hỏi đầu chỉ ghi nhận cái đã có; từ lần sau mới báo cái mới tới', () async {
      service.unread.add(_notice('cu'));
      alerts.start('u1');
      await pumpEventQueue();
      expect(alerts.takeNew(), isEmpty, reason: 'thông báo có từ trước không bật lời báo');

      service.unread.add(_notice('moi'));
      await alerts.check();
      expect(alerts.takeNew().map((n) => n.id), ['moi']);

      await alerts.check();
      expect(alerts.takeNew(), isEmpty, reason: 'không báo một tin hai lần');
    });

    test('thông báo huy hiệu không tính: lời báo huy hiệu đã lo phần đó', () async {
      alerts.start('u1');
      await pumpEventQueue();

      service.unread.addAll([_notice('huy-hieu', type: NotificationType.achievement), _notice('quan-tri')]);
      await alerts.check();

      expect(alerts.takeNew().map((n) => n.id), ['quan-tri']);
    });

    test('mất mạng lúc đầu: lần hỏi được đầu tiên mới là mốc, không báo dồn', () async {
      service
        ..offline = true
        ..unread.add(_notice('cu'));
      alerts.start('u1');
      await pumpEventQueue();

      service.offline = false;
      await alerts.check();
      expect(alerts.takeNew(), isEmpty);
    });

    testWidgets('hỏi lại theo chu kỳ cho tới khi dừng', (tester) async {
      alerts.start('u1');
      await tester.pump();
      expect(service.fetches, 1);

      await tester.pump(const Duration(minutes: 3));
      expect(service.fetches, 4);

      alerts.stop();
      await tester.pump(const Duration(minutes: 3));
      expect(service.fetches, 4);
    });

    test('đổi tài khoản: phản hồi của người trước không được báo cho người sau', () async {
      alerts.start('u1');
      await pumpEventQueue();
      service
        ..unread.add(_notice('cua-u1'))
        ..hold = Completer<void>();
      final check = alerts.check();
      alerts.start('u2');
      service.hold!.complete();
      await check;
      await pumpEventQueue();

      expect(alerts.takeNew(), isEmpty);
    });
  });

  group('NotificationAlertHost', () {
    late _FakeService service;
    late NotificationAlerts alerts;
    late List<String> feedback;

    Future<void> pumpHost(WidgetTester tester, {UserSettings settings = const UserSettings(), ThemeData? theme}) async {
      service = _FakeService();
      alerts = NotificationAlerts(service: service);
      feedback = [];
      final preferences = SettingsProvider(service: _StoredSettings(settings));
      await preferences.load();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _SignedInAuth()),
          ChangeNotifierProvider.value(value: alerts),
          ChangeNotifierProvider(create: (_) => NotificationProvider(service: service)),
          ChangeNotifierProvider.value(value: preferences),
          Provider.value(value: AlertFeedback(
            playSound: () async => feedback.add('âm báo'),
            vibrate: () async => feedback.add('rung'),
          )),
        ],
        child: MaterialApp(
          theme: theme,
          home: NotificationAlertHost(
            onOpenNotifications: () => feedback.add('mở Thông báo'),
            child: const Scaffold(body: Text('trong app')),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('quản trị gửi một thông báo: hiện tiêu đề kèm nút Xem, kêu và rung, chấm chuông cập nhật', (tester) async {
      await pumpHost(tester);
      service.unread.add(_notice('n1', title: 'Lịch thi thử N4 tuần sau'));

      await alerts.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Lịch thi thử N4 tuần sau'), findsOneWidget);
      expect(feedback, ['âm báo', 'rung']);
      expect(service.unreadCountCalls, greaterThan(0));

      await tester.tap(find.text('Xem'));
      await tester.pump();
      expect(feedback.last, 'mở Thông báo');
      alerts.stop();
    });

    testWidgets('nhiều thông báo cùng lúc gộp thành một lời báo', (tester) async {
      await pumpHost(tester);
      service.unread.addAll([_notice('n1'), _notice('n2')]);

      await alerts.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Bạn có 2 thông báo mới'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      alerts.stop();
    });

    testWidgets('giao diện tối: chuông cùng màu chữ của lời báo, không chìm vào nền', (tester) async {
      final dark = AppTheme.darkTheme;
      await pumpHost(tester, theme: dark);
      service.unread.add(_notice('n1'));

      await alerts.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      final bell = tester.widget<Icon>(find.byIcon(Icons.notifications_active_outlined));
      expect(bell.color, dark.snackBarTheme.contentTextStyle!.color);
      alerts.stop();
    });

    testWidgets('tắt "Nhận thông báo": không bật lời báo, thông báo vẫn nằm trong màn Thông báo', (tester) async {
      await pumpHost(tester, settings: const UserSettings(notificationsEnabled: false));
      service.unread.add(_notice('n1'));

      await alerts.check();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(SnackBar), findsNothing);
      expect(feedback, isEmpty);
      alerts.stop();
    });
  });
}

class _SignedInAuth extends AuthProvider {
  @override
  User? get user => User.fromJson(const {'_id': 'u1', 'TenDangNhap': 'lan', 'HoTen': 'Lan', 'Email': 'lan@example.invalid'});
}

/// Cài đặt đọc từ "server" giả, không gọi mạng.
class _StoredSettings implements SettingsService {
  _StoredSettings(this.stored);

  final UserSettings stored;

  @override
  Future<UserSettings> getSettings() async => stored;

  @override
  Future<void> saveSettings(UserSettings settings) async {}
}
