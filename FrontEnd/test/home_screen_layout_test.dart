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
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/app/theme/calm_colors.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/home/models/next_lesson.dart';
import 'package:apphoctiengnnhat/features/home/providers/home_provider.dart';
import 'package:apphoctiengnnhat/features/home/screens/home_screen.dart';
import 'package:apphoctiengnnhat/features/home/services/home_service.dart';
import 'package:apphoctiengnnhat/features/home/widgets/next_lesson_card.dart';
import 'package:apphoctiengnnhat/features/home/widgets/word_of_day_card.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';
import 'package:apphoctiengnnhat/features/news/providers/news_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/shared/widgets/content_pane.dart';

/// Backend rỗng: màn chủ phải dựng được cả khi chưa có streak, tiến độ, từ vựng
/// lẫn tin tức.
MockClient _backend() => MockClient((request) async => http.Response(
      jsonEncode({'data': [], 'total': 0}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));

/// Dữ liệu Trang chủ giả, không gọi mạng.
class _FakeHomeService extends HomeService {
  _FakeHomeService({this.next, this.word, this.unread = 0});

  final NextLesson? next;
  final Vocabulary? word;
  final int unread;

  @override
  Future<NextLesson?> loadNextLesson({required String fallbackLevel}) async => next;

  @override
  Future<Vocabulary?> loadWordOfDay({required String level, required DateTime today}) async => word;

  @override
  Future<int> unreadNotifications() async => unread;
}

Lesson _lesson({String id = 'l3', int order = 3, String title = 'Tình huống: Chọn cửa hàng phù hợp'}) =>
    Lesson.fromJson({
      '_id': id,
      'title': title,
      'level': 'N4',
      'order': order,
      'vocabularies': ['a', 'b', 'c'],
      'createdAt': '2026-09-01T00:00:00Z',
      'updatedAt': '2026-09-01T00:00:00Z',
    });

Vocabulary _word() => Vocabulary.fromJson({
      '_id': 'v1',
      'word': '猫',
      'hiragana': 'ねこ',
      'meaning': 'con mèo',
      'level': 'N5',
      'examples': [
        {'sentence': '猫が好きです。', 'meaning': 'Tôi thích mèo.'},
      ],
    });

Widget _app({required ThemeData theme, HomeService? service}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/lessons/:id', builder: (context, state) => Text('bài ${state.pathParameters['id']}')),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => StreakProvider()),
      ChangeNotifierProvider(create: (_) => NewsProvider()),
      ChangeNotifierProvider(create: (_) => HomeProvider(service: service)),
    ],
    child: MaterialApp.router(
      theme: theme,
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

/// Dựng màn ở một bề rộng cửa sổ và trả lỗi bố cục đầu tiên gặp phải (tràn
/// khung là lỗi, không phải cảnh báo).
Future<Object?> _pumpAt(WidgetTester tester, Size size, ThemeData theme, {HomeService? service}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(theme: theme, service: service));
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    final error = tester.takeException();
    if (error != null) return error;
  }
  return null;
}

/// Trang chủ có dữ liệu thật đầy đủ (bài học tiếp theo, từ của ngày) — nạp
/// thẳng vào provider vì `HomeScreen` chỉ nạp khi đã đăng nhập.
Future<Object?> _pumpWithData(WidgetTester tester, Size size, ThemeData theme, {int unread = 0}) async {
  final service = _FakeHomeService(
    next: pickNextLesson(level: 'N4', lessons: [for (var i = 1; i <= 19; i++) _lesson(id: 'l$i', order: i)], progress: [
      LessonProgressSummary(lessonId: 'l3', isCompleted: false, lastStudiedAt: DateTime(2026, 9, 27)),
    ]),
    word: _word(),
    unread: unread,
  );
  final error = await _pumpAt(tester, size, theme, service: service);
  if (error != null) return error;
  final context = tester.element(find.byType(HomeScreen));
  await context.read<HomeProvider>().load(userLevel: 'N4');
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    final error = tester.takeException();
    if (error != null) return error;
  }
  return null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('trên cửa sổ rộng, nội dung bó lại một cột và căn giữa', (tester) async {
    await http.runWithClient(() async {
      const windowWidth = 1920.0;
      final error = await _pumpAt(tester, const Size(windowWidth, 1400), AppTheme.lightTheme);
      expect(error, isNull, reason: '$error');

      final pane = tester.getRect(find.descendant(of: find.byType(ContentPane), matching: find.byType(Column)).first);
      expect(pane.width, lessThanOrEqualTo(AppContentWidth.feed + 2 * 20), reason: 'nội dung bị kéo giãn hết bề ngang');
      expect((pane.left - (windowWidth - pane.right)).abs(), lessThan(1), reason: 'cột nội dung lệch sang một bên');
    }, _backend);
  });

  testWidgets('Góc học tập: 7 mục, lưới 4 cột, hàng 2 thẳng cột với hàng 1', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(tester, const Size(390, 1600), AppTheme.lightTheme);
      expect(error, isNull, reason: '$error');

      expect(find.text('Góc học tập'), findsOneWidget);
      final labels = ['Bài học', 'Từ vựng', 'Kanji', 'Luyện tập', 'JLPT', 'Nhóm học', 'Sổ tay'];
      // Mép trên và tâm ngang của nhãn: nhãn dài có thể xuống hai dòng nên không so tâm dọc.
      final tops = [
        for (final label in labels)
          Offset(tester.getCenter(find.text(label).last).dx, tester.getTopLeft(find.text(label).last).dy),
      ];
      for (var i = 1; i < 4; i++) {
        expect(tops[i].dy, tops[0].dy, reason: '${labels[i]} phải cùng hàng 1');
      }
      expect(tops[4].dy, greaterThan(tops[0].dy), reason: 'JLPT xuống hàng 2');
      expect(tops[4].dx, closeTo(tops[0].dx, 1), reason: 'JLPT thẳng cột với Bài học');
      expect(tops[6].dx, closeTo(tops[2].dx, 1), reason: 'Sổ tay thẳng cột với Kanji');
      // Không còn dòng mô tả dưới tên mục.
      expect(find.text('Học từ vựng và ngữ pháp'), findsNothing);
    }, _backend);
  });

  testWidgets('không còn nút làm mới; thay bằng kéo xuống để làm mới', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(tester, const Size(390, 1200), AppTheme.lightTheme);
      expect(error, isNull, reason: '$error');
      expect(find.byTooltip('Làm mới'), findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byTooltip('Thông báo'), findsOneWidget);
      expect(find.byTooltip('Cài đặt'), findsOneWidget);
    }, _backend);
  });

  testWidgets('chưa có dữ liệu thật: thẻ bài học không hiện số giả, mục từ mới ẩn', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(tester, const Size(390, 1400), AppTheme.lightTheme);
      expect(error, isNull, reason: '$error');
      expect(find.byType(NextLessonCard), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing, reason: 'không có tiến độ thì không vẽ thanh');
      expect(find.textContaining(RegExp(r'Bài \d')), findsNothing);
      expect(find.byType(WordOfDayCard), findsNothing);
      expect(find.text('Từ mới hôm nay'), findsNothing);
    }, _backend);
  });

  testWidgets('có dữ liệu: bài học tiếp theo, tiến độ trình độ, từ của ngày kèm câu ví dụ', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpWithData(tester, const Size(390, 1600), AppTheme.lightTheme);
      expect(error, isNull, reason: '$error');

      expect(find.text('BÀI HỌC TIẾP THEO'), findsOneWidget);
      expect(find.text('Chọn cửa hàng phù hợp'), findsOneWidget, reason: 'bỏ tiền tố "Tình huống:"');
      expect(find.textContaining('Bài 3 ·'), findsOneWidget);
      expect(find.text('0/19 bài'), findsOneWidget);
      expect(find.text('Tiếp tục học →'), findsOneWidget);

      expect(find.byType(WordOfDayCard), findsOneWidget);
      expect(find.text('ねこ'), findsOneWidget);
      expect(find.text('猫が好きです。'), findsOneWidget);
      expect(find.bySemanticsLabel('Nghe phát âm'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục học →'));
      await tester.pumpAndSettle();
      expect(find.text('bài l3'), findsOneWidget, reason: 'mở đúng bài đang học dở');
    }, _backend);
  });

  testWidgets('chấm cam trên chuông chỉ hiện khi có thông báo chưa đọc', (tester) async {
    await http.runWithClient(() async {
      await _pumpWithData(tester, const Size(390, 1200), AppTheme.lightTheme, unread: 3);
      expect(find.byTooltip('Thông báo (có thông báo chưa đọc)'), findsOneWidget);
    }, _backend);
  });

  // Theme dựng trong thân test: dựng ở `main()` là nạp font ngoài vùng test.
  for (final (name, theme) in [('sáng', () => AppTheme.lightTheme), ('tối', () => AppTheme.darkTheme)]) {
    for (final width in [360.0, 390.0, 1280.0]) {
      testWidgets('chế độ $name, rộng ${width.toInt()}: không chỗ nào tràn khung', (tester) async {
        await http.runWithClient(() async {
          final error = await _pumpWithData(tester, Size(width, 1800), theme());
          expect(error, isNull, reason: '$error');
        }, _backend);
      });
    }
  }

  testWidgets('mọi nút bấm trên Trang chủ có vùng chạm ≥ 44×44', (tester) async {
    await http.runWithClient(() async {
      await _pumpWithData(tester, const Size(360, 1800), AppTheme.lightTheme);
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(const MinimumTapTargetGuideline(
        size: Size(44, 44),
        link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
      )));
      handle.dispose();
    }, _backend);
  });

  testWidgets('thanh trên chỉ có viền dưới khi nội dung đã cuộn lên dưới nó', (tester) async {
    await http.runWithClient(() async {
      await _pumpWithData(tester, const Size(390, 700), AppTheme.lightTheme);
      Color borderColor() => ((tester.widget<AppBar>(find.byType(AppBar)).shape as Border).bottom).color;

      expect(borderColor(), Colors.transparent, reason: 'đứng yên ở đầu trang: không viền');
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pump();
      expect(borderColor(), CalmColors.light.cardBorder, reason: 'đã cuộn: có viền 1px');
    }, _backend);
  });

  testWidgets('nền màn và thẻ theo bảng màu dịu', (tester) async {
    await http.runWithClient(() async {
      await _pumpWithData(tester, const Size(390, 1200), AppTheme.lightTheme);
      final scaffold = tester.widget<Scaffold>(find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scaffold)));
      expect(scaffold.backgroundColor, CalmColors.light.background);
    }, _backend);
  });
}
