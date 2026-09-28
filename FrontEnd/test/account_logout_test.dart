import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/shell/hub_screen.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/services/auth_service.dart';

/// Service giả: không chạm mạng, chỉ đếm số lần đăng xuất.
class _FakeAuthService extends AuthService {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}

/// Hub Tài khoản thật trong một router tối thiểu, có màn đăng nhập để thấy
/// được việc chuyển trang sau khi đăng xuất.
Widget _app(AuthProvider auth) {
  final router = GoRouter(
    initialLocation: '/account',
    routes: [
      GoRoute(
        path: '/account',
        builder: (context, state) =>
            const HubScreen(destinationPath: '/account'),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Text('Màn đăng nhập')),
      ),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
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

Future<void> _openAccountHub(WidgetTester tester, AuthProvider auth) async {
  // Đủ cao để cả mười mục lẫn ô Đăng xuất cùng nằm trong màn hình.
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(auth));
  await tester.pumpAndSettle();
}

final _logoutTile = find.text('Thoát khỏi tài khoản trên máy này');
final _confirmButton = find.widgetWithText(FilledButton, 'Đăng xuất');

void main() {
  testWidgets('hub Tài khoản có ô Đăng xuất đứng sau mọi mục điều hướng',
      (tester) async {
    await _openAccountHub(tester, AuthProvider(authService: _FakeAuthService()));

    expect(_logoutTile, findsOneWidget);
    expect(
      tester.getTopLeft(_logoutTile).dy,
      greaterThan(tester.getTopLeft(find.text('Đổi mật khẩu')).dy),
    );
  });

  testWidgets('bấm Hủy thì vẫn đăng nhập và ở lại hub', (tester) async {
    final service = _FakeAuthService();
    await _openAccountHub(tester, AuthProvider(authService: service));

    await tester.tap(_logoutTile);
    await tester.pumpAndSettle();
    expect(find.text('Bạn có chắc muốn đăng xuất?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();

    expect(service.logoutCalls, 0);
    expect(find.text('Màn đăng nhập'), findsNothing);
    expect(_logoutTile, findsOneWidget);
  });

  testWidgets('xác nhận thì đăng xuất đúng một lần rồi về màn đăng nhập',
      (tester) async {
    final service = _FakeAuthService();
    await _openAccountHub(tester, AuthProvider(authService: service));

    await tester.tap(_logoutTile);
    await tester.pumpAndSettle();
    await tester.tap(_confirmButton);
    await tester.pumpAndSettle();

    expect(service.logoutCalls, 1);
    expect(find.text('Màn đăng nhập'), findsOneWidget);
  });
}
