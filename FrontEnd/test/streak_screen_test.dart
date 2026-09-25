import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/streaks/models/streak_settings.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';
import 'package:apphoctiengnnhat/features/streaks/widgets/freeze_card.dart';
import 'package:apphoctiengnnhat/features/streaks/widgets/streak_hero_card.dart';

UserStreak _streak({
  int current = 5,
  bool studiedToday = false,
  String? lastActivityDay = '2026-09-24',
  int freezes = 2,
  List<String> pending = const [],
  int todayXp = 12,
}) =>
    UserStreak.fromJson({
      'current_streak': current,
      'longest_streak': 9,
      'total_xp': 240,
      'level': 3,
      'xp_to_next_level': 60,
      'total_active_days': 12,
      'last_activity_day': lastActivityDay,
      'studied_today': studiedToday,
      'freezes_available': freezes,
      'max_freezes': 2,
      'pending_frozen_days': pending,
      'freezes_after_pending': freezes - pending.length,
      'daily_goal': {'target_xp': 20, 'today_xp': todayXp},
    });

class _FakeStreakService extends StreakService {
  _FakeStreakService(this.streak);

  UserStreak streak;
  StreakSettings settings = const StreakSettings();
  Object? saveError;
  final List<Map<String, Object?>> saves = [];

  @override
  Future<UserStreak> getMyStreak() async => streak;

  @override
  Future<List<XPHistory>> getXPHistory() async => const [];

  @override
  Future<StreakSettings> getSettings() async => settings;

  @override
  Future<StreakSettings> updateSettings({
    int? dailyGoalXp,
    bool? reminderEnabled,
    String? reminderTime,
  }) async {
    saves.add({
      'daily_goal_xp': dailyGoalXp,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
    });
    if (saveError != null) throw saveError!;
    return settings;
  }
}

Future<_FakeStreakService> _pumpScreen(WidgetTester tester, UserStreak streak) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeStreakService(streak);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => StreakProvider(service: service),
      child: const MaterialApp(home: StreakScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('câu chữ trạng thái', () {
    test('không bao giờ khẳng định chuỗi sẽ đứt', () {
      final messages = [
        streakStatusMessage(_streak()),
        streakStatusMessage(_streak(pending: ['2026-09-23'])),
        streakStatusMessage(_streak(current: 0, pending: ['2026-09-20'])),
        streakStatusMessage(_streak(lastActivityDay: null, current: 0)),
        streakStatusMessage(_streak(studiedToday: true)),
      ];
      for (final message in messages) {
        expect(message.toLowerCase(), isNot(contains('sẽ đứt')), reason: message);
        expect(message.toLowerCase(), isNot(contains('mất chuỗi')), reason: message);
      }
    });

    test('chuỗi đứt nói rõ băng vẫn bị dùng nhưng không đủ giữ chuỗi', () {
      final message = pendingFreezeMessage(_streak(current: 0, freezes: 1, pending: ['2026-09-20']));
      expect(message, contains('không đủ giữ chuỗi'));
      expect(message, contains('20/09'));
      expect(pendingFreezeMessage(_streak()), isNull);
    });
  });

  testWidgets('màn hiện tiến độ mục tiêu, kho băng và trạng thái hôm nay', (tester) async {
    await _pumpScreen(tester, _streak(pending: ['2026-09-23']));

    expect(find.text('5 ngày liên tiếp'), findsOneWidget);
    expect(find.text('12/20 XP'), findsOneWidget);
    expect(find.text('Còn 8 XP nữa để đạt mục tiêu.'), findsOneWidget);
    expect(find.text('2/2 băng đang có'), findsOneWidget);
    expect(find.textContaining('băng sẽ che 23/09'), findsOneWidget);
    expect(find.textContaining('Học hôm nay để băng che'), findsOneWidget);
  });

  testWidgets('đã đạt mục tiêu thì báo đạt', (tester) async {
    await _pumpScreen(tester, _streak(todayXp: 26, studiedToday: true));

    expect(find.text('26/20 XP'), findsOneWidget);
    expect(find.text('Đã đạt mục tiêu hôm nay 🎉'), findsOneWidget);
  });

  testWidgets('sheet: đổi mục tiêu, bật nhắc rồi lưu đúng các trường đã đổi', (tester) async {
    final service = await _pumpScreen(tester, _streak());

    await tester.tap(find.text('Đổi mục tiêu'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, '20 XP'), findsOneWidget);
    expect(find.textContaining('áp dụng từ ngày mai'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '50 XP'));
    await tester.pumpAndSettle();
    expect(find.text('Mục tiêu mới áp dụng từ ngày mai. Hôm nay vẫn tính 20 XP.'), findsOneWidget);

    expect(find.text('Giờ nhắc (giờ Việt Nam)'), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Giờ nhắc (giờ Việt Nam)'), findsOneWidget);
    expect(find.textContaining('Chỉ nhắc khi bạn đang mở ứng dụng'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(service.saves, [
      {'daily_goal_xp': 50, 'reminder_enabled': true, 'reminder_time': null},
    ]);
    expect(find.byType(ChoiceChip), findsNothing, reason: 'lưu xong thì đóng sheet');
    expect(find.text('Đã lưu cài đặt.'), findsOneWidget);
  });

  testWidgets('sheet: server từ chối thì hiện lỗi ngay trong sheet và giữ sheet mở', (tester) async {
    final service = await _pumpScreen(tester, _streak());
    service.saveError = BadRequestException('Giờ nhắc phải trong khoảng 08:00–21:59.');

    await tester.tap(find.text('Đổi mục tiêu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '30 XP'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Giờ nhắc phải trong khoảng 08:00–21:59.'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
  });

  testWidgets('sheet: không đổi gì thì đóng mà không gọi server', (tester) async {
    final service = await _pumpScreen(tester, _streak());

    await tester.tap(find.text('Đổi mục tiêu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(service.saves, isEmpty);
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
