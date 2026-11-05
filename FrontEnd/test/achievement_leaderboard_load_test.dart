import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/features/achievements/providers/achievement_provider.dart';
import 'package:apphoctiengnnhat/features/achievements/screens/achievement_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/leaderboard_screen.dart';

const _responses = <String, Object>{
  '/api/achievement/my-achievements': {
    'earned': [],
    'locked': [
      {
        'progress': 0,
        'is_completed': false,
        'is_locked': true,
        'achievement': {'_id': 'a1', 'name_vi': 'Bước đầu', 'category': 'lesson'},
      },
    ],
  },
  '/api/achievement/stats': {'total_achievements': 0, 'earned_achievements': 0, 'completion_rate': '0'},
  '/api/streak/leaderboard': {
    'leaderboard': [
      {
        'rank': 1,
        'user': {'_id': 'u1', 'TenDangNhap': 'lan', 'HoTen': 'Lê Thu Lan'},
        'total_xp': 974,
        'level': 10,
        'current_streak': 2,
        'longest_streak': 9,
      },
    ],
  },
};

final _client = MockClient((request) async => http.Response(
      jsonEncode(_responses[request.url.path] ?? {}),
      _responses.containsKey(request.url.path) ? 200 : 404,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));

void main() {
  // Gọi notifyListeners ngay trong initState là đánh dấu cây widget khi nó đang dựng. Bản
  // debug báo lỗi; bản release trên web thì kẹt vòng xoay dù API đã trả dữ liệu.
  Future<void> pump(WidgetTester tester, Widget screen) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AchievementProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
        ],
        child: MaterialApp(home: screen),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }, () => _client);
  }

  testWidgets('màn Thành tích tải dữ liệu sau khung hình đầu rồi thoát vòng xoay', (tester) async {
    await pump(tester, const AchievementScreen());

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Đã đạt'), findsOneWidget);
  });

  testWidgets('màn Bảng xếp hạng tải dữ liệu sau khung hình đầu rồi thoát vòng xoay', (tester) async {
    await pump(tester, const LeaderboardScreen());

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Lê Thu Lan'), findsOneWidget);
  });
}
