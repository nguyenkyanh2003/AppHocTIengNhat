import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/shell/app_shell.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/lessons/providers/lesson_provider.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_list_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/lesson_level_bar.dart';

/// Bài học giả cùng hình dạng JSON mà `GET /api/lesson` thật đang trả.
Map<String, dynamic> _lesson(int index, String level) => {
      '_id': 'lesson-$level-$index',
      'title': 'Tình huống $level số $index',
      'level': level,
      'order': index,
      'description': 'Mô tả bài $index',
      'situation': 'train',
      'type': 'Tình huống',
      'dialogue': [],
      'can_do_goals': [],
      'vocabularies': [],
      'grammars': [],
      'kanjis': [],
      'createdAt': '2026-09-15 10:26:18',
      'updatedAt': '2026-09-15 10:26:18',
    };

final _requests = <String>[];

typedef _Delay = Duration Function(String? level);

/// Backend giả đúng số bài từng cấp như DB thật; độ trễ theo cấp để dựng lại
/// cảnh hai bộ lọc chạy chồng nhau và về lệch nhau.
MockClient _backend({_Delay? lessonDelay, _Delay? situationDelay}) {
  final all = [
    for (var i = 1; i <= 8; i++) _lesson(i, 'N5'),
    for (var i = 1; i <= 6; i++) _lesson(i, 'N4'),
    for (var i = 1; i <= 4; i++) _lesson(i, 'N3'),
    for (var i = 1; i <= 2; i++) _lesson(i, 'N2'),
  ];

  return MockClient((request) async {
    _requests.add(request.url.toString());
    final query = request.url.queryParameters;
    final level = query['level'];

    if (request.url.path.endsWith('/lesson/situations')) {
      await Future<void>.delayed(situationDelay?.call(level) ?? Duration.zero);
      return http.Response(
        jsonEncode({'data': level == null ? ['bus', 'train'] : ['train'], 'total': 1}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    await Future<void>.delayed(lessonDelay?.call(level) ?? Duration.zero);
    final page = int.parse(query['page'] ?? '1');
    final limit = int.parse(query['limit'] ?? '10');
    final matched = level == null ? all : all.where((l) => l['level'] == level).toList();
    final items = matched.skip((page - 1) * limit).take(limit).toList();

    return http.Response(
      jsonEncode({
        'totalItems': matched.length,
        'totalPages': (matched.length / limit).ceil(),
        'currentPage': page,
        'data': items,
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

/// Dựng màn Bài học đúng như app thật: trong `AppShell`, qua GoRouter. Hộp
/// thoại và navigator lồng chỉ lộ lỗi khi có đủ cấu trúc này.
Widget _shellApp() {
  final router = GoRouter(
    initialLocation: '/lessons',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/lessons', builder: (context, state) => const LessonListScreen()),
          GoRoute(path: '/elsewhere', builder: (context, state) => const SizedBox()),
        ],
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LessonProvider()),
    ],
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
}

/// Chờ màn yên có giới hạn rồi lấy lỗi binding bắt được — không ghi đè
/// `FlutterError.onError`, vì `expect` trước khi trả handler làm treo test.
Future<void> _settle(WidgetTester tester, String step) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } on FlutterError catch (error) {
    fail('[$step] màn hình không yên sau 5s giả. Request: $_requests\n$error');
  }
  final exception = tester.takeException();
  expect(exception, isNull, reason: '[$step] $exception\nRequest: $_requests');
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 970);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_shellApp());
  await _settle(tester, 'mở màn');
}

Finder _levelChip(String label) => find.widgetWithText(ChoiceChip, label);

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(_levelChip(label)).selected;

LessonProvider _provider(WidgetTester tester) => Provider.of<LessonProvider>(
      tester.element(find.byType(AppShell)),
      listen: false,
    );

Set<String> _listedLevels(WidgetTester tester) =>
    _provider(tester).lessons.map((lesson) => lesson.level).toSet();

Future<void> _scrollTo(WidgetTester tester, String title) => tester.scrollUntilVisible(
      find.text(title),
      300,
      scrollable: find
          .descendant(of: find.byType(RefreshIndicator), matching: find.byType(Scrollable))
          .first,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _requests.clear();
  });

  group('hàng chọn trình độ', () {
    testWidgets('luôn hiện đủ Mọi trình độ và N5–N1, chọn sẵn trình độ mặc định', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        for (final label in ['Mọi trình độ', 'N5', 'N4', 'N3', 'N2', 'N1']) {
          expect(_levelChip(label), findsOneWidget, reason: label);
        }
        // Người học chưa có trình độ trong hồ sơ bắt đầu từ N5.
        expect(_isSelected(tester, 'N5'), isTrue);
        expect(_isSelected(tester, 'Mọi trình độ'), isFalse);
        expect(_requests.first, contains('level=N5'));
      }, _backend);
    });

    testWidgets('không còn chip có dấu X hay hộp thoại lọc ẩn sau icon phễu', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        expect(find.byType(InputChip), findsNothing);
        expect(find.byIcon(Icons.filter_list), findsNothing);
      }, _backend);
    });

    testWidgets('bấm N4 tải bài N4 và chủ đề của N4', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        await tester.tap(_levelChip('N4'));
        await _settle(tester, 'chọn N4');

        expect(_isSelected(tester, 'N4'), isTrue);
        expect(_isSelected(tester, 'N5'), isFalse);
        expect(_requests, contains(endsWith('/lesson?page=1&limit=10&level=N4')));
        expect(_requests, contains(endsWith('/lesson/situations?level=N4')));
        expect(find.text('Tình huống N4 số 1'), findsOneWidget);
        expect(find.textContaining('Tình huống N5'), findsNothing);
      }, _backend);
    });

    testWidgets('Mọi trình độ tải bài của mọi cấp', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        await tester.tap(_levelChip('Mọi trình độ'));
        await _settle(tester, 'chọn Mọi trình độ');

        expect(_isSelected(tester, 'Mọi trình độ'), isTrue);
        expect(_requests.last, isNot(contains('level=')));
        expect(find.text('Trang 1 / 2'), findsOneWidget);
        await _scrollTo(tester, 'Tình huống N4 số 1');
        expect(find.text('Tình huống N4 số 1'), findsOneWidget);
      }, _backend);
    });

    testWidgets('bấm lại đúng trình độ đang chọn không gửi request mới', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);
        final before = _requests.length;

        await tester.tap(_levelChip('N5'));
        await _settle(tester, 'bấm lại N5');

        expect(_requests.length, before);
        expect(_isSelected(tester, 'N5'), isTrue);
      }, _backend);
    });

    testWidgets('rời màn rồi quay lại vẫn giữ trình độ vừa chọn', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);
        await tester.tap(_levelChip('N4'));
        await _settle(tester, 'chọn N4');
        final before = _requests.length;

        final router = GoRouter.of(tester.element(find.byType(LessonListScreen)));
        router.go('/elsewhere');
        await _settle(tester, 'rời màn');
        expect(find.byType(LessonListScreen), findsNothing);
        router.go('/lessons');
        await _settle(tester, 'quay lại màn');

        expect(_isSelected(tester, 'N4'), isTrue);
        expect(find.text('Tình huống N4 số 1'), findsOneWidget);
        expect(_requests.length, before, reason: 'quay lại không được nạp lại về N5');
      }, _backend);
    });
  });

  group('LessonLevelBar', () {
    Future<List<String?>> pumpBar(WidgetTester tester, {String? userLevel}) async {
      final changes = <String?>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LessonLevelBar(
            selectedLevel: 'N5',
            userLevel: userLevel,
            onChanged: changes.add,
          ),
        ),
      ));
      return changes;
    }

    testWidgets('đánh dấu trình độ trong hồ sơ của người học', (tester) async {
      await pumpBar(tester, userLevel: 'N4');

      expect(
        find.descendant(of: _levelChip('N4'), matching: find.byIcon(Icons.person)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('hồ sơ chưa có trình độ thì không đánh dấu chip nào', (tester) async {
      await pumpBar(tester);

      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('báo cấp mới khi bấm cấp khác, null khi bấm Mọi trình độ', (tester) async {
      final changes = await pumpBar(tester);

      await tester.tap(_levelChip('N5'));
      await tester.tap(_levelChip('N3'));
      await tester.tap(_levelChip('Mọi trình độ'));

      expect(changes, ['N3', null]);
    });
  });

  group('đổi trình độ khi đang tải', () {
    testWidgets('giữ danh sách trên màn và chỉ hiện thanh tải mảnh', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        await tester.tap(_levelChip('N4'));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('Tình huống N5'), findsWidgets,
            reason: 'danh sách cũ phải còn trên màn trong lúc tải bộ lọc mới');
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing,
            reason: 'không được thay cả danh sách bằng vòng xoay toàn màn');

        await _settle(tester, 'N4 về');
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('Tình huống N4 số 1'), findsOneWidget);
      }, () => _backend(lessonDelay: (level) => const Duration(milliseconds: 400)));
    });

    testWidgets('response của bộ lọc cũ về muộn không ghi đè bộ lọc mới', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        await tester.tap(_levelChip('Mọi trình độ')); // chậm 800ms
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(_levelChip('N4')); // nhanh 50ms, mới hơn
        await _settle(tester, 'N4 về');
        // Màn đã yên từ lúc N4 về; phải bơm qua mốc 800ms thì response cũ mới tới.
        await tester.pump(const Duration(seconds: 1));
        await _settle(tester, 'response cũ về');

        expect(_listedLevels(tester), {'N4'},
            reason: 'bài của "mọi trình độ" về muộn đã ghi đè N4');
        expect(_provider(tester).situations, ['train'],
            reason: 'chủ đề của "mọi trình độ" về muộn đã ghi đè chủ đề N4');
        expect(_isSelected(tester, 'N4'), isTrue);
        expect(find.textContaining('Tình huống N5'), findsNothing);
      }, () {
        Duration slowForAllLevels(String? level) => switch (level) {
              null => const Duration(milliseconds: 800),
              'N4' => const Duration(milliseconds: 50),
              _ => Duration.zero,
            };
        return _backend(lessonDelay: slowForAllLevels, situationDelay: slowForAllLevels);
      });
    });

    testWidgets('đổi trình độ liên tiếp không sinh lỗi ở frame nào', (tester) async {
      await http.runWithClient(() async {
        await _open(tester);

        final frameErrors = <String>[];
        for (final label in ['N4', 'Mọi trình độ', 'N3', 'N5']) {
          await tester.tap(_levelChip(label));
          for (var frame = 0; frame < 6; frame++) {
            await tester.pump(const Duration(milliseconds: 40));
            final exception = tester.takeException();
            if (exception != null) frameErrors.add('$label/frame $frame: $exception');
          }
        }
        await _settle(tester, 'sau chuỗi đổi trình độ');

        expect(frameErrors, isEmpty, reason: frameErrors.join('\n'));
        expect(_isSelected(tester, 'N5'), isTrue);
        expect(_listedLevels(tester), {'N5'});
      }, () => _backend(lessonDelay: (level) => const Duration(milliseconds: 120)));
    });
  });
}
