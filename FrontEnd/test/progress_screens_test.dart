import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/app_providers.dart';
import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/shell/app_navigation.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/progress/screens/learning_history_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/progress_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/user_statistics_screen.dart';

const _headers = {'content-type': 'application/json; charset=utf-8'};

String _today() => DateTime.now().toIso8601String().substring(0, 10);

/// Số liệu chọn lạ để không thể trùng với số cũ từng gắn cứng trên giao diện.
Map<String, Object?> _backend(String path) {
  if (path.endsWith('/dashboard/stats')) {
    return {
      'vocabulary_learned': 137,
      'kanji_learned': 29,
      'kanji_reviewing': 13,
      'exercises_completed': 7,
      'lessons_completed': 3,
      'total_study_time': 5400,
      'current_streak': 4,
      'total_xp': 910,
      'level': 2,
    };
  }
  if (path.endsWith('/dashboard/breakdown')) {
    return {
      'lessons_by_level': [
        {'_id': 'N4', 'completed': 2, 'in_progress': 2},
      ],
      'exercises_by_type': [
        {'_id': 'grammar', 'count': 6, 'average_score': 81.5, 'passed': 5},
      ],
    };
  }
  if (path.endsWith('/streak/my-streak')) {
    return {
      'current_streak': 4,
      'longest_streak': 11,
      'total_xp': 910,
      'level': 2
    };
  }
  if (path.endsWith('/achievement/my-achievements')) {
    return {
      'earned': [
        {
          '_id': 'a1',
          'user': 'u1',
          'is_completed': true,
          'progress': 1,
          'earned_at': '2026-11-01T00:00:00.000Z',
          'achievement': {
            '_id': 'x',
            'name_vi': 'Bước chân đầu tiên',
            'description_vi': 'Học bài đầu',
            'xp_reward': 40
          },
        },
      ],
      'locked': [],
    };
  }
  return {};
}

List<Object?> _backendList(String path) {
  if (path.endsWith('/dashboard/timeline')) {
    return [
      {'date': _today(), 'exercises': 2, 'lessons': 1, 'time': 1200, 'xp': 77},
    ];
  }
  if (path.endsWith('/streak/xp-history')) {
    return [
      {
        'amount': 15,
        'reason': 'Làm bài tập',
        'earned_at': '2026-11-02T00:00:00.000Z'
      },
      {
        'amount': 9,
        'reason': 'Ôn tập SRS',
        'earned_at': '2026-11-02T00:00:00.000Z'
      },
    ];
  }
  return [];
}

http.Client _client() => MockClient((request) async {
      final path = request.url.path;
      final isList = path.endsWith('/timeline') ||
          path.endsWith('/heatmap') ||
          path.endsWith('/xp-history');
      final body =
          isList ? jsonEncode(_backendList(path)) : jsonEncode(_backend(path));
      return http.Response.bytes(utf8.encode(body), 200, headers: _headers);
    });

Widget _app(GoRouter router) => MultiProvider(
      providers: createAppProviders(),
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN')],
        locale: const Locale('vi', 'VN'),
        routerConfig: router,
      ),
    );

Future<void> _pump(WidgetTester tester, Widget screen,
    {double height = 2400}) async {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      _app(GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => screen)])));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('lối vào từ màn Tiến độ', () {
    for (final (label, path, target) in [
      ('Lịch sử học', '/learning-history', 'màn lịch sử'),
      ('Thống kê chi tiết', '/statistics', 'màn thống kê'),
    ]) {
      testWidgets('bấm "$label" mở $path', (tester) async {
        await http.runWithClient(() async {
          final router = GoRouter(
            initialLocation: '/progress',
            routes: [
              GoRoute(
                  path: '/progress',
                  builder: (_, __) => const ProgressDashboardScreen()),
              GoRoute(
                  path: path, builder: (_, __) => Scaffold(body: Text(target))),
            ],
          );
          await tester.pumpWidget(_app(router));
          await tester.pumpAndSettle();

          await tester.tap(find.text(label));
          await tester.pumpAndSettle();

          expect(find.text(target), findsOneWidget);
        }, _client);
      });
    }

    test('hai màn con tô sáng mục Tiến độ trên thanh điều hướng', () {
      final destinations = [
        const AppDestination(
            path: '/home',
            label: 'Trang chủ',
            icon: Icons.home,
            selectedIcon: Icons.home),
        const AppDestination(
          path: '/progress',
          label: 'Tiến độ',
          icon: Icons.insights,
          selectedIcon: Icons.insights,
          relatedPaths: ['/learning-history', '/statistics', '/goals'],
        ),
      ];

      expect(
          AppNavigation.indexOfLocation(destinations, '/learning-history'), 1);
      expect(AppNavigation.indexOfLocation(destinations, '/statistics'), 1);
      expect(AppNavigation.indexOfLocation(destinations, '/khac'), -1);
    });
  });

  group('màn Thống kê chi tiết', () {
    testWidgets('hiện số thật của tài khoản, không còn số gắn cứng',
        (tester) async {
      await http.runWithClient(() async {
        await _pump(tester, const UserStatisticsScreen());

        expect(find.text('137'), findsOneWidget);
        expect(find.text('29'), findsOneWidget);
        expect(find.text('11 ngày'), findsOneWidget);
        expect(find.text('1 giờ 30 phút'), findsOneWidget);
        expect(find.text('2/4 bài'), findsOneWidget);
        expect(find.text('81.5%'), findsOneWidget);

        for (final fake in [
          '240h',
          '1,250',
          '340',
          '75%',
          '68%',
          'Xuất PDF',
          'Chia Sẻ',
          'Tính năng sắp có...'
        ]) {
          expect(find.textContaining(fake), findsNothing,
              reason: 'Còn số giả: $fake');
        }
      }, _client);
    });

    testWidgets('nút Xuất dữ liệu mở màn xuất dữ liệu thật', (tester) async {
      await http.runWithClient(() async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          initialLocation: '/statistics',
          routes: [
            GoRoute(
                path: '/statistics',
                builder: (_, __) => const UserStatisticsScreen()),
            GoRoute(
                path: '/export',
                builder: (_, __) => const Scaffold(body: Text('màn xuất'))),
          ],
        );
        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xuất dữ liệu học tập'));
        await tester.pumpAndSettle();

        expect(find.text('màn xuất'), findsOneWidget);
      }, _client);
    });
  });

  group('màn Lịch sử học', () {
    testWidgets(
        'tab Tổng quan hiện thành tích thật, "Xem tất cả" mở màn thành tích',
        (tester) async {
      await http.runWithClient(() async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          initialLocation: '/learning-history',
          routes: [
            GoRoute(
                path: '/learning-history',
                builder: (_, __) => const LearningHistoryScreen()),
            GoRoute(
                path: '/achievements',
                builder: (_, __) =>
                    const Scaffold(body: Text('màn thành tích'))),
          ],
        );
        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        expect(find.text('Bước chân đầu tiên'), findsOneWidget);
        expect(find.text('+40 XP'), findsOneWidget);
        for (final fake in [
          'Chuỗi 7 ngày',
          'Học sinh chăm chỉ',
          'Bậc thầy từ vựng'
        ]) {
          expect(find.text(fake), findsNothing,
              reason: 'Còn thành tích giả: $fake');
        }

        await tester.tap(find.text('Xem tất cả'));
        await tester.pumpAndSettle();
        expect(find.text('màn thành tích'), findsOneWidget);
      }, _client);
    });

    testWidgets('tab Hoạt động lọc được theo nhóm', (tester) async {
      await http.runWithClient(() async {
        await _pump(tester, const LearningHistoryScreen());
        await tester.tap(find.text('Hoạt động'));
        await tester.pumpAndSettle();

        expect(find.text('Làm bài tập'), findsOneWidget);
        expect(find.text('Ôn tập SRS'), findsOneWidget);

        await tester.tap(find.text('Ôn tập'));
        await tester.pumpAndSettle();
        expect(find.text('Làm bài tập'), findsNothing);
        expect(find.text('Ôn tập SRS'), findsOneWidget);

        await tester.tap(find.text('Thưởng'));
        await tester.pumpAndSettle();
        expect(find.text('Ôn tập SRS'), findsNothing);
        expect(find.textContaining('Không có hoạt động'), findsOneWidget);
      }, _client);
    });

    testWidgets('tab Thống kê lấy thời gian từ dữ liệu thật', (tester) async {
      await http.runWithClient(() async {
        await _pump(tester, const LearningHistoryScreen());
        await tester.tap(find.text('Thống kê'));
        await tester.pumpAndSettle();

        // Hôm nay và 7 ngày đều là 20 phút; tổng 1 giờ 30 phút.
        expect(find.text('20 phút'), findsNWidgets(2));
        expect(find.text('1 giờ 30 phút'), findsOneWidget);
        for (final fake in ['45 phút', '5.2 giờ', '40%', '25%', '15%']) {
          expect(find.textContaining(fake), findsNothing,
              reason: 'Còn số giả: $fake');
        }
      }, _client);
    });
  });
}
