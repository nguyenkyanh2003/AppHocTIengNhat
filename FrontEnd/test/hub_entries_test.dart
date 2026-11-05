import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/router/app_router.dart';
import 'package:apphoctiengnnhat/app/shell/app_navigation.dart';
import 'package:apphoctiengnnhat/app/shell/hub_screen.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';

/// Gom route theo đường dẫn đầy đủ, kể cả route con.
Map<String, GoRoute> _routes(List<RouteBase> routes, [String parent = '']) {
  final found = <String, GoRoute>{};
  for (final route in routes) {
    var prefix = parent;
    if (route is GoRoute) {
      final base = parent == '/' ? '' : parent;
      prefix = route.path.startsWith('/') ? route.path : '$base/${route.path}';
      found[prefix] = route;
    }
    found.addAll(_routes(route.routes, prefix));
  }
  return found;
}

void main() {
  testWidgets('không ô nào trên trang hub dẫn về một trang hub khác',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox.shrink();
      }),
    ));
    await tester.pump();

    final router = AppRouter.create(AuthProvider());
    addTearDown(router.dispose);
    final routes = _routes(router.configuration.routes);

    final loops = <String>[];
    for (final destination in AppNavigation.destinations(context)) {
      for (final entry in destination.entries) {
        final route = routes[entry.path];
        expect(route, isNotNull, reason: '${entry.path} chưa có route');
        final state = GoRouterState(
          router.configuration,
          uri: Uri.parse(entry.path),
          matchedLocation: entry.path,
          fullPath: entry.path,
          pathParameters: const {},
          pageKey: ValueKey(entry.path),
        );
        if (route!.builder!(context, state) is HubScreen) {
          loops.add('${entry.label} (${entry.path})');
        }
      }
    }

    expect(loops, isEmpty,
        reason: 'Bấm vào ô mà chỉ thấy lại trang hub: ${loops.join(', ')}');
  });

  testWidgets('mọi màn sau đăng nhập đều tô sáng một mục trên thanh điều hướng',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox.shrink();
      }),
    ));
    await tester.pump();

    final destinations = AppNavigation.destinations(context);
    const outsideShell = {
      '/splash',
      '/forbidden',
      '/lessons/:id/study',
      '/jlpt/:examId/exam',
      '/flashcards/:deckId/study',
      '/vocabulary/study',
      '/admin/lessons/:id/transcript',
    };
    final unmatched = [
      for (final path in AppRouter.contract)
        if (!AppRouter.publicPaths.contains(path) &&
            !outsideShell.contains(path) &&
            AppNavigation.indexOfLocation(
                    destinations, path.replaceAll(RegExp(r':\w+'), 'x')) <
                0)
          path,
    ];

    expect(unmatched, isEmpty,
        reason: 'Mở các màn này thì thanh dưới tô sáng nhầm Trang chủ');
  });
}
