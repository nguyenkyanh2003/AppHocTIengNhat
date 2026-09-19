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
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/home/screens/home_screen.dart';
import 'package:apphoctiengnnhat/features/news/providers/news_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/shared/widgets/chunky_card.dart';
import 'package:apphoctiengnnhat/shared/widgets/content_pane.dart';

/// Backend rỗng: màn chủ phải dựng được cả khi chưa có streak lẫn tin tức.
MockClient _backend() => MockClient((request) async => http.Response(
      jsonEncode({'data': [], 'total': 0}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));

Widget _app({required ThemeData theme}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => StreakProvider()),
      ChangeNotifierProvider(create: (_) => NewsProvider()),
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
Future<Object?> _pumpAt(WidgetTester tester, Size size, ThemeData theme) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(theme: theme));
  for (var frame = 0; frame < 8; frame++) {
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
      final error = await _pumpAt(
        tester,
        const Size(windowWidth, 1400),
        AppTheme.lightTheme,
      );
      expect(error, isNull, reason: '$error');

      // Đo cột nội dung bên trong: bản thân `ContentPane` là một `Align` nên
      // lúc nào cũng rộng bằng cửa sổ.
      final pane = tester.getRect(find.descendant(
        of: find.byType(ContentPane),
        matching: find.byType(Column),
      ).first);
      expect(pane.width, lessThanOrEqualTo(AppContentWidth.reading + AppSpacing.page.horizontal),
          reason: 'nội dung bị kéo giãn hết bề ngang cửa sổ');
      // Căn giữa: lề trái và lề phải bằng nhau (sai số 1px cho số lẻ).
      expect((pane.left - (windowWidth - pane.right)).abs(), lessThan(1),
          reason: 'cột nội dung lệch sang một bên');
    }, _backend);
  });

  testWidgets('trên màn hẹp không có chỗ nào tràn khung', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(
        tester,
        const Size(400, 900),
        AppTheme.lightTheme,
      );
      expect(error, isNull, reason: '$error');
    }, _backend);
  });

  testWidgets('chế độ tối dựng được và thẻ vẫn có mép nổi khối', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(
        tester,
        const Size(1280, 1400),
        AppTheme.darkTheme,
      );
      expect(error, isNull, reason: '$error');
      expect(find.byType(ChunkyCard), findsWidgets);
    }, _backend);
  });

  testWidgets('hai thẻ chỉ số dùng hai màu khác nhau', (tester) async {
    await http.runWithClient(() async {
      final error = await _pumpAt(
        tester,
        const Size(1280, 1400),
        AppTheme.lightTheme,
      );
      expect(error, isNull, reason: '$error');

      final colors = tester
          .widgetList<ChunkyCard>(find.byType(ChunkyCard))
          .map((card) => card.color)
          .toList();
      expect(colors, contains(AppColors.streak));
      expect(colors, contains(AppColors.xp));
      expect(AppColors.streak, isNot(AppColors.xp));
      // Hero là hành động chính: xanh lá, không dùng lại tím thương hiệu.
      expect(colors, contains(AppColors.heroAction));
      expect(colors, isNot(contains(AppColors.primary)));
    }, _backend);
  });
}
