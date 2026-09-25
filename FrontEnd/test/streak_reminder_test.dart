import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/models/streak_settings.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_reminder.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';
import 'package:apphoctiengnnhat/features/streaks/widgets/streak_reminder_host.dart';
import 'package:apphoctiengnnhat/shared/models/user.dart';

/// Giờ Việt Nam `hh:mm` ngày 25/9/2026, quy ra UTC.
DateTime _vn(int hour, int minute, {int day = 25}) =>
    DateTime.utc(2026, 9, day, hour, minute).subtract(const Duration(hours: 7));

ReminderDecision _decide(DateTime now, {bool enabled = true, bool handled = false, String time = '20:00'}) =>
    decideReminder(now: now, enabled: enabled, reminderTime: time, windowEnd: '21:59', handledToday: handled);

/// Timer giả: không tự chạy, chỉ ghi lại để test gọi tay.
class _FakeTimer implements Timer {
  _FakeTimer(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('quyết định lúc nhắc', () {
    test('tắt nhắc thì không làm gì', () {
      expect(_decide(_vn(20, 30), enabled: false), isA<ReminderOff>());
    });

    test('trước giờ đã chọn thì đợi đúng khoảng còn lại', () {
      final decision = _decide(_vn(19, 15));
      expect(decision, isA<ReminderWait>());
      expect((decision as ReminderWait).delay, const Duration(minutes: 45));
    });

    test('mở app sau giờ đã chọn nhưng còn trong khung thì nhắc ngay', () {
      expect(_decide(_vn(20, 0)), isA<ReminderShowNow>());
      expect(_decide(_vn(21, 59)), isA<ReminderShowNow>());
    });

    test('từ 22:00 trở đi không nhắc, đợi tới giờ đó ngày mai', () {
      final decision = _decide(_vn(22, 0));
      expect(decision, isA<ReminderWait>());
      expect((decision as ReminderWait).delay, const Duration(hours: 22));
    });

    test('qua nửa đêm không nhắc bù cho ngày cũ', () {
      // 00:30 ngày 26: hôm qua chưa nhắc cũng không nhắc bù; đợi 20:00 ngày 26.
      final decision = _decide(_vn(0, 30, day: 26));
      expect(decision, isA<ReminderWait>());
      expect((decision as ReminderWait).delay, const Duration(hours: 19, minutes: 30));
    });

    test('hôm nay đã xử lý thì đợi tới mai', () {
      final decision = _decide(_vn(20, 30), handled: true);
      expect((decision as ReminderWait).delay, const Duration(hours: 23, minutes: 30));
    });
  });

  group('bộ lập lịch', () {
    late DateTime now;
    late List<_FakeTimer> timers;
    late int shown;
    late bool? studied;
    late StreakSettings? settings;

    StreakReminderScheduler build() => StreakReminderScheduler(
          userId: 'u1',
          readSettings: () => settings,
          syncStudiedToday: () async => studied,
          showReminder: () => shown += 1,
          clock: () => now,
          timerFactory: (delay, callback) {
            final timer = _FakeTimer(delay, callback);
            timers.add(timer);
            return timer;
          },
        );

    setUp(() {
      now = _vn(20, 30);
      timers = [];
      shown = 0;
      studied = false;
      settings = const StreakSettings(reminderEnabled: true, reminderTime: '20:00');
    });

    test('chưa học thì nhắc một lần rồi hẹn sang mai', () async {
      final scheduler = build();
      await scheduler.reschedule();

      expect(shown, 1);
      expect(timers.last.delay, const Duration(hours: 23, minutes: 30));

      // Dựng lại (tải lại trang) cùng ngày: không nhắc lần hai.
      await build().reschedule();
      expect(shown, 1);
    });

    test('đã học thì không nhắc nhưng vẫn đánh dấu ngày đã xử lý', () async {
      studied = true;
      await build().reschedule();

      expect(shown, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReminderScheduler.handledKey('u1', '2026-09-25')), isTrue);
    });

    test('mất mạng thì không nhắc, không đánh dấu, thử lại sau', () async {
      studied = null;
      final scheduler = build();
      await scheduler.reschedule();

      expect(shown, 0);
      expect(timers.last.delay, StreakReminderScheduler.retryDelay);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReminderScheduler.handledKey('u1', '2026-09-25')), isNull);

      // Có mạng lại: lần thử sau nhắc bình thường.
      studied = false;
      timers.last.callback();
      await pumpEventQueue();
      expect(shown, 1);
    });

    test('hẹn giờ tới lúc thì xét lại theo giờ thật, không nhắc mù', () async {
      now = _vn(19, 0);
      final scheduler = build();
      await scheduler.reschedule();
      expect(shown, 0);
      expect(timers.last.delay, const Duration(hours: 1));

      // Máy ngủ quên, timer chạy lúc 22:10: quá khung nên không nhắc.
      now = _vn(22, 10);
      timers.last.callback();
      await pumpEventQueue();
      expect(shown, 0);
    });

    test('mỗi người dùng có dấu riêng trên cùng thiết bị', () async {
      await build().reschedule();
      expect(shown, 1);

      final other = StreakReminderScheduler(
        userId: 'u2',
        readSettings: () => settings,
        syncStudiedToday: () async => false,
        showReminder: () => shown += 1,
        clock: () => now,
        timerFactory: (delay, callback) => _FakeTimer(delay, callback),
      );
      await other.reschedule();
      expect(shown, 2);
    });

    test('đã huỷ thì việc đang dở không nhắc nữa', () async {
      final gate = Completer<bool?>();
      final scheduler = StreakReminderScheduler(
        userId: 'u1',
        readSettings: () => settings,
        syncStudiedToday: () => gate.future,
        showReminder: () => shown += 1,
        clock: () => now,
        timerFactory: (delay, callback) => _FakeTimer(delay, callback),
      );
      final pending = scheduler.reschedule();
      await pumpEventQueue();
      scheduler.dispose();
      gate.complete(false);
      await pending;

      expect(shown, 0);
    });
  });

  group('host', () {
    Future<void> pumpHost(
      WidgetTester tester, {
      required bool studiedToday,
      Key? key,
      _FakeStreakService? service,
    }) async {
      service ??= _FakeStreakService(studiedToday: studiedToday);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => _SignedInAuth()),
            ChangeNotifierProvider(create: (_) => StreakProvider(service: service)),
          ],
          child: MaterialApp(
            home: StreakReminderHost(
              key: key,
              clock: () => _vn(20, 30),
              child: const Scaffold(body: Text('trong app')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('chưa học thì hiện lời nhắc, không khẳng định chuỗi sẽ đứt', (tester) async {
      await pumpHost(tester, studiedToday: false);

      final banner = find.byKey(const Key('streak-reminder-banner'));
      expect(banner, findsOneWidget);
      expect(find.text('Hôm nay bạn chưa học bài nào. Dành vài phút ôn tập nhé?'), findsOneWidget);
      expect(find.textContaining('đứt'), findsNothing);

      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(banner, findsNothing);
    });

    testWidgets('đã học thì không nhắc', (tester) async {
      await pumpHost(tester, studiedToday: true);
      expect(find.byKey(const Key('streak-reminder-banner')), findsNothing);
    });

    testWidgets('mất mạng lúc mở app: quay lại app thì tải lại cài đặt rồi mới nhắc', (tester) async {
      final service = _FakeStreakService(studiedToday: false, settingsFailures: 1);
      await pumpHost(tester, studiedToday: false, service: service);
      expect(find.byKey(const Key('streak-reminder-banner')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streak-reminder-banner')), findsOneWidget);
    });

    testWidgets('dựng lại trong cùng ngày không nhắc lần hai', (tester) async {
      await pumpHost(tester, studiedToday: false, key: const Key('lan-1'));
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      await pumpHost(tester, studiedToday: false, key: const Key('lan-2'));
      expect(find.byKey(const Key('streak-reminder-banner')), findsNothing);
    });
  });
}

class _SignedInAuth extends AuthProvider {
  _SignedInAuth();

  @override
  User? get user => User(
        id: 'u1',
        username: 'demo',
        email: 'demo@example.test',
        role: 'user',
        createdAt: DateTime(2026),
      );
}

class _FakeStreakService extends StreakService {
  _FakeStreakService({required this.studiedToday, this.settingsFailures = 0});

  final bool studiedToday;

  /// Số lần đọc cài đặt đầu tiên thất bại, giả lập mất mạng.
  int settingsFailures;

  @override
  Future<UserStreak> getMyStreak() async => UserStreak.fromJson({'current_streak': 3, 'studied_today': studiedToday});

  @override
  Future<StreakSettings> getSettings() async {
    if (settingsFailures > 0) {
      settingsFailures -= 1;
      throw Exception('mất mạng');
    }
    return const StreakSettings(reminderEnabled: true, reminderTime: '20:00');
  }
}
