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
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/exercise/services/exercise_service.dart';
import 'package:apphoctiengnnhat/features/home/widgets/home_stat_cards.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_detail_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/learning_history_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/user_statistics_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_screen.dart';
import 'package:apphoctiengnnhat/shared/widgets/async_view.dart';

const _headers = {'content-type': 'application/json; charset=utf-8'};
const _lessonId = '507f1f77bcf86cd799439011';

/// Số chọn lạ để không thể trùng với giá trị mặc định 0 hay 1 của giao diện.
Object _ok(String path) {
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
    return {'lessons_by_level': [], 'exercises_by_type': []};
  }
  if (path.endsWith('/dashboard/timeline') ||
      path.endsWith('/dashboard/heatmap')) {
    return [];
  }
  if (path.endsWith('/streak/my-streak')) {
    return {
      'current_streak': 4,
      'longest_streak': 11,
      'total_xp': 910,
      'level': 2,
    };
  }
  if (path.endsWith('/streak/xp-history')) {
    return [
      {
        'amount': 15,
        'reason': 'Làm bài tập',
        'earned_at': '2026-11-02T00:00:00.000Z',
      },
    ];
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
            'xp_reward': 40,
          },
        },
      ],
      'locked': [],
    };
  }
  if (path.endsWith('/lesson/$_lessonId')) {
    return {
      '_id': _lessonId,
      'title': 'Tự giới thiệu',
      'level': 'N5',
      'order': 1,
    };
  }
  if (path.endsWith('/lesson-progress/lesson/$_lessonId')) {
    return {
      '_id': 'p1',
      'lesson': _lessonId,
      'is_completed': true,
      'overall_progress': 100,
    };
  }
  return {};
}

/// Máy chủ chạy bình thường, chỉ các đường dẫn chứa [down] là mất kết nối.
class _Backend {
  _Backend(this.down);

  Set<String> down;

  http.Client client() => MockClient((request) async {
        final path = request.url.path;
        if (down.any(path.contains)) {
          throw http.ClientException('Failed to fetch', request.url);
        }
        return http.Response.bytes(utf8.encode(jsonEncode(_ok(path))), 200,
            headers: _headers);
      });
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
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
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => screen)],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('màn Lịch sử học', () {
    testWidgets('thiếu thành tích thì báo lỗi, không kết luận "chưa mở khoá"',
        (tester) async {
      final backend = _Backend({'/achievement/'});
      await http.runWithClient(() async {
        await _pump(tester, const LearningHistoryScreen());

        expect(find.textContaining('Chưa mở khoá'), findsNothing);
        expect(find.byType(ErrorStateView), findsOneWidget);
        // Các khối còn lại vẫn dùng được.
        expect(find.text('137'), findsOneWidget);
        expect(find.text('Ngày liên tiếp'), findsOneWidget);

        backend.down = {};
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorStateView), findsNothing);
        expect(find.text('Bước chân đầu tiên'), findsOneWidget);
      }, backend.client);
    });

    testWidgets('thiếu chuỗi ngày thì báo lỗi, không hiện số 0 và lịch trống',
        (tester) async {
      final backend = _Backend({'/streak/my-streak'});
      await http.runWithClient(() async {
        await _pump(tester, const LearningHistoryScreen());

        expect(find.text('Ngày liên tiếp'), findsNothing);
        expect(find.text('Lịch học tuần này'), findsNothing);
        expect(find.byType(ErrorStateView), findsOneWidget);
        expect(find.text('137'), findsOneWidget);

        backend.down = {};
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(find.text('Ngày liên tiếp'), findsOneWidget);
        expect(find.text('11'), findsOneWidget);
      }, backend.client);
    });

    testWidgets('thiếu số liệu tiến độ thì khối chuỗi ngày vẫn hiện',
        (tester) async {
      final backend = _Backend({'/progress/'});
      await http.runWithClient(() async {
        await _pump(tester, const LearningHistoryScreen());

        expect(find.text('Từ vựng đã học'), findsNothing);
        expect(find.byType(ErrorStateView), findsOneWidget);
        expect(find.text('Ngày liên tiếp'), findsOneWidget);
        expect(find.text('Bước chân đầu tiên'), findsOneWidget);
      }, backend.client);
    });
  });

  testWidgets('Thống kê chi tiết: thiếu chuỗi ngày thì không hiện "0 ngày"',
      (tester) async {
    final backend = _Backend({'/streak/my-streak'});
    await http.runWithClient(() async {
      await _pump(tester, const UserStatisticsScreen());

      expect(find.text('Chuỗi dài nhất'), findsNothing);
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('137'), findsOneWidget);

      backend.down = {};
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('11 ngày'), findsOneWidget);
    }, backend.client);
  });

  testWidgets('Chuỗi ngày: thiếu lịch sử XP thì báo lỗi ngay tại khối đó',
      (tester) async {
    final backend = _Backend({'/streak/xp-history', '/streak/settings'});
    await http.runWithClient(() async {
      await _pump(tester, const StreakScreen());

      expect(find.byType(ErrorStateView), findsOneWidget);

      backend.down = {'/streak/settings'};
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsNothing);
      expect(find.text('Làm bài tập'), findsOneWidget);
    }, backend.client);
  });

  testWidgets('Chi tiết bài học: thiếu tiến độ thì báo lỗi, bài vẫn đọc được',
      (tester) async {
    final backend = _Backend({'/lesson-progress/'});
    await http.runWithClient(() async {
      await _pump(tester, const LessonDetailScreen(lessonId: _lessonId));

      expect(find.textContaining('Tự giới thiệu'), findsWidgets);
      expect(find.byType(ErrorStateView), findsOneWidget);

      backend.down = {};
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsNothing);
    }, backend.client);
  });

  testWidgets(
      'Trang chủ: chưa có số chuỗi ngày thì hiện dấu gạch, không hiện 0',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: const Scaffold(
        body: HomeStatCards(streakDays: null, totalXp: null),
      ),
    ));
    await tester.pump();

    expect(find.text('—'), findsNWidgets(2));
    expect(find.textContaining('0'), findsNothing);
  });

  test('Bài tập: một cấp lỗi thì báo lỗi, không lặng lẽ thiếu bài', () async {
    await http.runWithClient(() async {
      await expectLater(ExerciseService().getAllExercises(), throwsException);
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/N3')) {
                throw http.ClientException('Failed to fetch', request.url);
              }
              return http.Response('[]', 200, headers: _headers);
            }));
  });
}
