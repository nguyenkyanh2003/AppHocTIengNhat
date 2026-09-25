import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/features/streaks/models/calendar_day.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_calendar_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_calendar_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';

// 10:00 ngày 12/9/2026 giờ Việt Nam.
final _now = DateTime.utc(2026, 9, 12, 3);
const _today = '2026-09-12';

StreakDay _day(String key, String status, {int xp = 0, int reviews = 0}) =>
    StreakDay(dayKey: key, status: status, origin: 'activity', directXp: xp, reviewCount: reviews);

/// Service giả: trả ngày theo tháng; `gate` giữ phản hồi lại để dựng cuộc đua.
class _FakeStreakService extends StreakService {
  _FakeStreakService({this.days = const [], UserStreak? streak})
      : streak = streak ?? UserStreak.fromJson({});

  final List<StreakDay> days;
  final UserStreak streak;
  final Map<String, Completer<void>> gates = {};
  final List<(String?, String?)> requests = [];

  @override
  Future<UserStreak> getMyStreak() async => streak;

  @override
  Future<StreakDaysPage> getDays({String? from, String? to, String? cursor, int limit = 100}) async {
    requests.add((from, to));
    await gates[from]?.future;
    return StreakDaysPage(
      days: days.where((day) => day.dayKey.compareTo(from!) >= 0 && day.dayKey.compareTo(to!) <= 0).toList(),
      nextCursor: null,
      from: from!,
      to: to!,
    );
  }
}

void main() {
  group('phân loại ngày', () {
    CalendarDayKind kind(String day, {StreakDay? record, Set<String> pending = const {}}) =>
        classifyCalendarDay(
          dayKey: day,
          todayKey: _today,
          record: record,
          pendingFrozenDays: pending,
          trackingStartedDay: '2026-09-03',
        );

    test('ngày có bản ghi theo đúng trạng thái đã ghi', () {
      expect(kind('2026-09-10', record: _day('2026-09-10', 'studied')), CalendarDayKind.studied);
      expect(kind('2026-09-09', record: _day('2026-09-09', 'frozen')), CalendarDayKind.frozen);
      expect(kind('2026-09-01', record: _day('2026-09-01', 'legacy')), CalendarDayKind.legacy);
      expect(kind(_today, record: _day(_today, 'studied')), CalendarDayKind.studied);
    });

    test('tương lai không bao giờ là ngày nghỉ', () {
      expect(kind('2026-09-13'), CalendarDayKind.future);
      expect(kind('2026-10-01', pending: {'2026-10-01'}), CalendarDayKind.future);
    });

    test('hôm nay chưa học không phải ngày nghỉ', () {
      expect(kind(_today), CalendarDayKind.today);
    });

    test('ngày băng sẽ che khác ngày băng đã che, và khác ngày nghỉ', () {
      expect(kind('2026-09-11', pending: {'2026-09-11'}), CalendarDayKind.pendingFrozen);
      expect(kind('2026-09-08'), CalendarDayKind.missed);
    });

    test('trước khi bắt đầu theo dõi thì không nói gì', () {
      expect(kind('2026-09-02'), CalendarDayKind.untracked);
      expect(
        classifyCalendarDay(dayKey: '2026-09-05', todayKey: _today),
        CalendarDayKind.untracked,
        reason: 'chưa từng theo dõi thì không có ngày nào là nghỉ',
      );
    });
  });

  group('lưới tháng', () {
    test('bắt đầu từ thứ Hai, đủ số ngày', () {
      // 1/9/2026 là thứ Ba: một ô trống ở đầu.
      final september = monthCells(2026, 9);
      expect(september.first, isNull);
      expect(september[1], '2026-09-01');
      expect(september.whereType<String>().length, 30);
      // 1/2/2027 là thứ Hai: không có ô trống; tháng 2 không nhuận có 28 ngày.
      final february = monthCells(2027, 2);
      expect(february.first, '2027-02-01');
      expect(february.length, 28);
    });

    test('mô tả ngày đã học có XP và lượt ôn', () {
      expect(
        describeCalendarDay(CalendarDayKind.studied, _day('2026-09-10', 'studied', xp: 14, reviews: 3)),
        'Đã học · 14 XP · 3 lượt ôn',
      );
      expect(describeCalendarDay(CalendarDayKind.today, null), 'Hôm nay bạn chưa học.');
    });
  });

  group('provider', () {
    test('tải đúng khoảng ngày của tháng đang xem', () async {
      final service = _FakeStreakService(days: [_day('2026-09-10', 'studied')]);
      final provider = StreakCalendarProvider(service: service, clock: () => _now);

      await provider.load();

      expect(service.requests.single, ('2026-09-01', '2026-09-30'));
      expect(provider.days.valueOrNull?.keys, ['2026-09-10']);
      expect(provider.canGoNext, isFalse, reason: 'không xem được tháng tương lai');
      expect(provider.canGoPrevious('2026-08-15'), isTrue);
      expect(provider.canGoPrevious('2026-09-03'), isFalse);
      expect(provider.canGoPrevious(null), isFalse);
    });

    test('bấm chuyển tháng liên tục: phản hồi của tháng đã rời không ghi đè', () async {
      final service = _FakeStreakService(days: [
        _day('2026-09-10', 'studied'),
        _day('2026-08-20', 'studied'),
      ]);
      final provider = StreakCalendarProvider(service: service, clock: () => _now);
      // Phản hồi tháng 9 về chậm hơn phản hồi tháng 8.
      service.gates['2026-09-01'] = Completer<void>();

      final september = provider.load();
      final august = provider.showPrevious();
      await august;
      service.gates['2026-09-01']!.complete();
      await september;

      expect(provider.month, DateTime.utc(2026, 8));
      expect(provider.days.valueOrNull?.keys, ['2026-08-20']);
    });
  });

  testWidgets('màn lịch tô đúng loại ngày và báo chi tiết khi chạm', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _FakeStreakService(
      days: [
        _day('2026-09-10', 'studied', xp: 14, reviews: 3),
        _day('2026-09-09', 'frozen'),
        _day('2026-09-04', 'legacy'),
      ],
      streak: UserStreak.fromJson({
        'current_streak': 2,
        'last_activity_day': '2026-09-10',
        'tracking_started_day': '2026-09-03',
        'first_day': '2026-09-04',
        'freezes_available': 1,
        'pending_frozen_days': ['2026-09-11'],
      }),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StreakProvider(service: service),
        child: MaterialApp(home: StreakCalendarScreen(service: service, clock: () => _now)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tháng 9/2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 10 tháng 9: Đã học'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 9 tháng 9: Băng đã che'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 11 tháng 9: Băng sẽ che (dự kiến)'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 4 tháng 9: Dữ liệu cũ, chưa xác minh'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 12 tháng 9: Hôm nay chưa học'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 8 tháng 9: Nghỉ'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 20 tháng 9: Chưa tới'), findsOneWidget);
    expect(find.bySemanticsLabel('Ngày 2 tháng 9: Chưa theo dõi'), findsOneWidget);
    expect(find.text('Tháng này: 1 ngày học · 1 ngày được băng che.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-2026-09-10')));
    await tester.pump();
    expect(find.text('10/09: Đã học · 14 XP · 3 lượt ôn'), findsOneWidget);

    // Đang ở tháng hiện tại nên không tới được tháng sau; ngày sớm nhất trong
    // lịch cũng thuộc tháng 9 nên không có gì để lùi về.
    final next = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right));
    final previous = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left));
    expect(next.onPressed, isNull);
    expect(previous.onPressed, isNull);
  });
}
