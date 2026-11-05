import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/progress/providers/progress_provider.dart';
import 'package:apphoctiengnnhat/features/progress/screens/progress_dashboard_screen.dart';

/// Trả dữ liệu rỗng cho mọi API thống kê — test chỉ cần khung màn Tiến độ.
final _backend = MockClient((_) async => http.Response(jsonEncode({'data': {}}), 200,
    headers: {'content-type': 'application/json; charset=utf-8'}));

void main() {
  testWidgets('màn Tiến độ có lối vào Mục tiêu học tập', (tester) async {
    await http.runWithClient(() async {
      final router = GoRouter(
        initialLocation: '/progress',
        routes: [
          GoRoute(path: '/progress', builder: (context, state) => const ProgressDashboardScreen()),
          GoRoute(path: '/goals', builder: (context, state) => const Scaffold(body: Text('màn mục tiêu'))),
        ],
      );
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ProgressProvider(),
        child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mục tiêu học tập'));
      await tester.pumpAndSettle();

      expect(find.text('màn mục tiêu'), findsOneWidget);
    }, () => _backend);
  });
}
