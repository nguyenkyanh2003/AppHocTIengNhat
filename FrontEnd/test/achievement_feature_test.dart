import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/achievements/models/achievement.dart';
import 'package:apphoctiengnnhat/features/achievements/providers/achievement_provider.dart';
import 'package:apphoctiengnnhat/features/achievements/screens/achievement_screen.dart';
import 'package:apphoctiengnnhat/features/achievements/services/achievement_service.dart';

Map<String, dynamic> _definition(
  String name, {
  int goal = 10,
  String category = 'vocabulary',
  String rarity = 'common',
}) =>
    {
      '_id': name,
      'name': name,
      'name_vi': name,
      'description_vi': 'Mô tả $name',
      'icon': '📚',
      'category': category,
      'requirement_type': 'count',
      'requirement_value': goal,
      'xp_reward': 20,
      'rarity': rarity,
    };

Map<String, dynamic> _locked(Map<String, dynamic> definition, int progress) => {
      'achievement': definition,
      'progress': progress,
      'is_completed': false,
      'is_locked': true,
    };

Map<String, dynamic> _earned(Map<String, dynamic> definition, String at) => {
      '_id': 'ua-${definition['name']}',
      'user': 'u1',
      'achievement': definition,
      'progress': definition['requirement_value'],
      'is_completed': true,
      'earned_at': at,
    };

MyAchievements _sample() => MyAchievements.fromJson({
      'earned': [
        _earned(_definition('Cũ', category: 'lesson'), '2026-10-01T00:00:00Z'),
        _earned(_definition('Mới', category: 'lesson'), '2026-11-01T00:00:00Z'),
      ],
      'locked': [
        _locked(_definition('Xa', goal: 1000, category: 'xp'), 50),
        _locked(_definition('Gần', goal: 100, category: 'xp'), 50),
        _locked(_definition('Đủ', goal: 10), 10),
      ],
      'total': 34,
      'completed': 2,
    });

class _FakeService implements AchievementService {
  _FakeService(this.responses);

  /// Mỗi lượt tải lấy một phần tử: dữ liệu, exception hoặc Completer đang chờ.
  final List<Object> responses;

  @override
  Future<MyAchievements> getMyAchievements() async {
    final next = responses.removeAt(0);
    if (next is Completer<MyAchievements>) return next.future;
    if (next is Exception) throw next;
    return next as MyAchievements;
  }
}

ApiException _offline() => ApiException('Mất kết nối');

Widget _screen(AchievementProvider provider) => ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AchievementScreen(),
      ),
    );

void main() {
  group('dữ liệu', () {
    test('đọc đúng phản hồi của server; huy hiệu khoá không có ngày đạt', () {
      final mine = _sample();

      expect(mine.total, 34);
      expect(mine.completed, 2);
      expect(mine.locked.first.earnedAt, isNull);
      expect(mine.earned.first.earnedAt, isNotNull);
      expect(mine.completionRate, closeTo(2 / 34, 0.001));
    });

    test('đã đạt mới nhất trước, rồi tới huy hiệu gần đạt nhất theo tỉ lệ', () {
      expect(
        _sample().inCategory(null).map((i) => i.achievement.name),
        ['Mới', 'Cũ', 'Đủ', 'Gần', 'Xa'],
      );
    });

    test('lọc theo nhóm', () {
      expect(
        _sample().inCategory('xp').map((i) => i.achievement.name),
        ['Gần', 'Xa'],
      );
    });

    test('đủ tiêu chí mà chưa được cấp, kể cả ngưỡng hỏng', () {
      final mine = _sample();
      final ready = mine.locked.firstWhere((i) => i.achievement.name == 'Đủ');
      final far = mine.locked.firstWhere((i) => i.achievement.name == 'Xa');
      final broken = UserAchievement.fromJson(
        _locked(_definition('Hỏng', goal: 0), 5),
      );

      expect(ready.isReadyToClaim, isTrue);
      expect(far.isReadyToClaim, isFalse);
      expect(broken.isReadyToClaim, isFalse);
      expect(broken.completionRatio, 0);
    });
  });

  group('provider', () {
    test('lần đầu tải hỏng thì báo lỗi', () async {
      final provider = AchievementProvider(
        service: _FakeService([_offline()]),
      );

      expect(await provider.loadMyAchievements(), 'Mất kết nối');
      expect(provider.mine, isA<ViewFailure<MyAchievements>>());
    });

    test('tải lại hỏng thì giữ dữ liệu cũ và trả câu báo lỗi', () async {
      final provider = AchievementProvider(
        service: _FakeService([_sample(), _offline()]),
      );

      await provider.loadMyAchievements();
      expect(await provider.loadMyAchievements(), 'Mất kết nối');
      expect(provider.mine.valueOrNull?.total, 34);
    });

    test('phản hồi về sau khi đăng xuất không ghi đè', () async {
      final pending = Completer<MyAchievements>();
      final provider = AchievementProvider(service: _FakeService([pending]));

      final load = provider.loadMyAchievements();
      provider.clear();
      pending.complete(_sample());
      await load;

      expect(provider.mine, isA<ViewIdle<MyAchievements>>());
    });

    test('phản hồi của lượt cũ về muộn không đè lượt mới', () async {
      final old = Completer<MyAchievements>();
      final provider = AchievementProvider(
        service: _FakeService([
          old,
          MyAchievements.fromJson(const {'total': 7, 'completed': 1}),
        ]),
      );

      final first = provider.loadMyAchievements();
      await provider.loadMyAchievements();
      old.complete(_sample());
      await first;

      expect(provider.mine.valueOrNull?.total, 7);
    });
  });

  group('màn hình', () {
    Future<AchievementProvider> pump(
      WidgetTester tester, {
      List<Object>? responses,
    }) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = AchievementProvider(
        service: _FakeService(responses ?? [_sample()]),
      );
      await tester.pumpWidget(_screen(provider));
      await tester.pump();
      await tester.pump();
      return provider;
    }

    testWidgets('đầu màn hiện đúng số server đã đếm', (tester) async {
      await pump(tester);

      expect(find.text('2/34'), findsOneWidget);
      expect(find.text('6%'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('huy hiệu đã đạt có ngày, còn khoá có tiến độ và phần thưởng',
        (tester) async {
      await pump(tester);

      expect(find.textContaining('01/11/2026'), findsOneWidget);
      expect(find.textContaining('50/100 •'), findsOneWidget);
      expect(find.textContaining('+20 XP'), findsWidgets);
    });

    testWidgets('đủ tiêu chí thì nói rõ, không để 10/10 mà vẫn khoá',
        (tester) async {
      await pump(tester);

      expect(find.textContaining('10/10'), findsNothing);
      expect(
        find.text('Đã đủ điều kiện, sẽ nhận ở lần học tiếp theo'),
        findsOneWidget,
      );
    });

    testWidgets('tab dùng tên tiếng Việt và lọc đúng nhóm', (tester) async {
      await pump(tester);
      expect(find.text('Chuỗi ngày', skipOffstage: false), findsOneWidget);
      expect(find.text('Streak', skipOffstage: false), findsNothing);

      final tab = find.text('Kinh nghiệm', skipOffstage: false);
      await tester.ensureVisible(tab);
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();

      expect(find.text('Gần'), findsOneWidget);
      expect(find.text('Đủ'), findsNothing);
    });

    testWidgets('kéo tải lại hỏng thì báo nhẹ, danh sách vẫn còn',
        (tester) async {
      await pump(tester, responses: [_sample(), _offline()]);

      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator).first)
          .onRefresh;
      await refresh();
      await tester.pump();

      expect(find.text('Mất kết nối'), findsOneWidget);
      expect(find.text('2/34'), findsOneWidget);
    });

    testWidgets('chưa có dữ liệu mà lỗi thì có nút thử lại, không báo rỗng',
        (tester) async {
      await pump(tester, responses: [_offline(), _sample()]);

      expect(find.text('Chưa có thành tích nào'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();

      expect(find.text('2/34'), findsOneWidget);
    });
  });
}
