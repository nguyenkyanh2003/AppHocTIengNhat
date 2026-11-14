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
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_detail_screen.dart';

const _id = '507f1f77bcf86cd799439011';

Map<String, dynamic> _question(int n) => {
      '_id': 'q$n',
      'content': 'Câu $n',
      'answers': [
        {'_id': 'q$n-a', 'content': 'Đáp án A'},
        {'_id': 'q$n-b', 'content': 'Đáp án B'},
      ],
    };

/// Bài một phút, hai câu; ghi lại mọi lần nộp.
class _Backend {
  final submissions = <Map<String, dynamic>>[];

  http.Client get client => MockClient((request) async {
        final path = request.url.path;
        Object body = const {};
        if (request.method == 'POST' && path.endsWith('/exercise/submit/$_id')) {
          submissions.add(jsonDecode(request.body) as Map<String, dynamic>);
          body = {'_id': 'r1', 'exercise_id': _id, 'score': 0, 'total_questions': 2};
        } else if (path.endsWith('/exercise/$_id')) {
          body = {
            '_id': _id,
            'title': 'Bài có giới hạn giờ',
            'type': 'Từ vựng',
            'level': 'N5',
            'time_limit': 1,
            'questions': [_question(1), _question(2)],
          };
        }
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
            headers: const {'content-type': 'application/json; charset=utf-8'});
      });
}

Widget _app() => MultiProvider(
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
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (context, state) => const ExerciseDetailScreen(exerciseId: _id)),
          GoRoute(path: '/exercise/result/:id', builder: (context, state) => const Text('Trang kết quả')),
        ]),
      ),
    );

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hết giờ thì nộp ngay một lần, không hỏi "nộp không?" mỗi giây', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = _Backend();

    await http.runWithClient(() async {
      await tester.pumpWidget(_app());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text('Bắt đầu làm bài'));
      await tester.pump();

      // Một câu chưa trả lời; thời gian trôi quá giới hạn 1 phút vài giây.
      for (var second = 0; second < 64; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 300));
    }, () => backend.client);

    expect(find.text('Chưa hoàn thành'), findsNothing, reason: 'hết giờ không còn gì để hỏi');
    expect(backend.submissions, hasLength(1));
    expect(find.text('Trang kết quả'), findsOneWidget);
  });
}
