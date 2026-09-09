import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/shell/app_navigation.dart';
import 'package:apphoctiengnnhat/app/shell/app_shell.dart';
import 'package:apphoctiengnnhat/app/shell/hub_screen.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';

/// Các bề rộng nghiệm thu, kèm **hai bên mỗi breakpoint**.
///
/// Lỗi bố cục hay nấp đúng ở ranh giới: một bên còn thanh dưới, bên kia đã có
/// rail chiếm 80–256px, nên chỉ đo các mốc tròn là bỏ sót.
const _widths = <double>[
  360, // điện thoại nhỏ
  414,
  599, // ngay dưới mốc rail
  600, // đúng mốc rail
  601, // ngay trên mốc rail
  768, // máy tính bảng
  839,
  840,
  841,
  1023, // ngay dưới mốc rail mở rộng
  1024, // đúng mốc rail mở rộng
  1025,
  1440,
  1919,
  1920,
];

Widget _app({required String location, required Widget page}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => page),
          GoRoute(
            path: '/study',
            builder: (context, state) =>
                const HubScreen(destinationPath: '/study'),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) =>
                const HubScreen(destinationPath: '/account'),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) =>
                const HubScreen(destinationPath: '/admin'),
          ),
        ],
      ),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(),
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

/// Đặt kích thước cửa sổ giả lập rồi dựng lại cây.
Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  Widget app, {
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Chuỗi tiếng Nhật dài và nhãn tiếng Việt có dấu là thứ hay làm tràn.
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('không tràn bố cục', () {
    for (final path in ['/study', '/account', '/admin']) {
      testWidgets('trang hub $path ở mọi bề rộng đã chốt', (tester) async {
        addTearDown(tester.view.reset);

        for (final width in _widths) {
          await _pumpAt(
            tester,
            width,
            _app(location: path, page: const SizedBox()),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$path tràn ở bề rộng $width',
          );
        }
      });
    }

    testWidgets('cửa sổ thấp: rail cuộn được thay vì tràn', (tester) async {
      addTearDown(tester.view.reset);

      // 6 đích đến trên cửa sổ cao 320px là trường hợp rail chắc chắn không
      // đủ chỗ; `NavigationRail` tự nó không cuộn nên đây là bài kiểm thật.
      await _pumpAt(
        tester,
        1024,
        _app(location: '/study', page: const SizedBox()),
        height: 320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('cỡ chữ hệ thống phóng to không làm vỡ shell', (tester) async {
      addTearDown(tester.view.reset);

      for (final width in [360.0, 600.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: _app(location: '/account', page: const SizedBox()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'tràn ở bề rộng $width với cỡ chữ 1.6x',
        );
      }
    });
  });

  group('hình dạng điều hướng đổi đúng mốc', () {
    testWidgets('dưới 600 dùng thanh dưới, không dùng rail', (tester) async {
      addTearDown(tester.view.reset);
      await _pumpAt(
        tester,
        AppBreakpoints.rail - 1,
        _app(location: '/study', page: const SizedBox()),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('từ 600 dùng rail, không dùng thanh dưới', (tester) async {
      addTearDown(tester.view.reset);
      await _pumpAt(
        tester,
        AppBreakpoints.rail,
        _app(location: '/study', page: const SizedBox()),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('dưới 1024 rail thu gọn, từ 1024 rail mở rộng', (tester) async {
      addTearDown(tester.view.reset);

      await _pumpAt(
        tester,
        AppBreakpoints.railExtended - 1,
        _app(location: '/study', page: const SizedBox()),
      );
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );

      await _pumpAt(
        tester,
        AppBreakpoints.railExtended,
        _app(location: '/study', page: const SizedBox()),
      );
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
    });

    testWidgets('không phải admin thì rail không có mục Quản trị', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      await _pumpAt(
        tester,
        1024,
        _app(location: '/study', page: const SizedBox()),
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
    });
  });

  group('AppNavigation', () {
    testWidgets('mobile và desktop dùng chung một danh sách đích đến', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      late List<AppDestination> narrow;
      late List<AppDestination> wide;

      await _pumpAt(
        tester,
        360,
        _app(
          location: '/home',
          page: Builder(
            builder: (context) {
              narrow = AppNavigation.visibleDestinations(
                context,
                isAdmin: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await _pumpAt(
        tester,
        1440,
        _app(
          location: '/home',
          page: Builder(
            builder: (context) {
              wide = AppNavigation.visibleDestinations(context, isAdmin: false);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        narrow.map((d) => d.path).toList(),
        wide.map((d) => d.path).toList(),
      );
    });
  });
}
