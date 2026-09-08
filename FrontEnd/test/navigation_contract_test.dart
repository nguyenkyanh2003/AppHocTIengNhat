import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/router/app_router.dart';
import 'package:apphoctiengnnhat/features/auth/screens/reset_password_screen.dart';

void main() {
  test('named route contract stays stable', () {
    expect(AppRouter.routes.keys.toSet(), {
      '/login',
      '/register',
      '/home',
      '/profile',
      '/lessons',
      '/vocabulary',
      '/kanji',
      '/grammar',
      '/exercise',
      '/exercise-history',
      '/notebook',
      '/report',
      '/search',
      '/payment',
      '/statistics',
      '/goals',
      '/friend-leaderboard',
      '/jlpt',
      '/jlpt-practice',
      '/settings',
      '/notifications',
      '/export',
      '/offline-mode',
      '/notification-settings',
      '/help',
      '/learning-history',
      '/change-password',
      '/admin/dashboard',
      '/admin/users',
      '/admin/content',
      '/admin/reports',
      '/admin/achievements',
      '/admin/analytics',
      '/admin/transactions',
    });
  });

  test('generated route contract stays stable', () {
    expect(
      AppRouter.onGenerateRoute(
        const RouteSettings(name: '/vocabulary-detail', arguments: 'id'),
      ),
      isNotNull,
    );
    expect(
      AppRouter.onGenerateRoute(
        const RouteSettings(name: '/kanji-detail', arguments: 'id'),
      ),
      isNotNull,
    );
    expect(
      AppRouter.onGenerateRoute(
        const RouteSettings(name: '/exercise-detail', arguments: 'id'),
      ),
      isNotNull,
    );
    expect(
      AppRouter.onGenerateRoute(
        const RouteSettings(name: '/exercise-result'),
      ),
      isNotNull,
    );
    expect(
      AppRouter.onGenerateRoute(const RouteSettings(name: '/unknown')),
      isNull,
    );
  });

  group('route đặt lại mật khẩu', () {
    ResetPasswordScreen screenOf(String name) {
      final route = AppRouter.onGenerateRoute(RouteSettings(name: name))
          as MaterialPageRoute<dynamic>;
      return route.builder(_FakeContext()) as ResetPasswordScreen;
    }

    test('link từ email mang token vào màn hình', () {
      expect(screenOf('/reset-password?token=abc123').token, 'abc123');
    });

    test('token được giải mã percent-encoding', () {
      expect(screenOf('/reset-password?token=a%2Bb%20c').token, 'a+b c');
    });

    test('thiếu token vẫn mở được màn hình để báo link hỏng', () {
      expect(screenOf('/reset-password').token, isNull);
      expect(screenOf('/reset-password?token=').token, isEmpty);
    });

    test('RouteSettings được giữ lại', () {
      final route =
          AppRouter.onGenerateRoute(const RouteSettings(name: '/reset-password'))
              as MaterialPageRoute<dynamic>;
      expect(route.settings.name, '/reset-password');
    });

    test('URL thật trong email dẫn đúng vào màn hình', () {
      // Backend dựng link dạng `<FRONTEND_URL>/#/reset-password?token=...`.
      // Với hash routing, phần Flutter nhận được chính là fragment của URL đó.
      const emailLink =
          'http://localhost:8080/#/reset-password?token=eyJhbGciOi.J9';
      final routeName = Uri.parse(emailLink).fragment;

      expect(routeName, '/reset-password?token=eyJhbGciOi.J9');
      expect(screenOf(routeName).token, 'eyJhbGciOi.J9');
    });

    test('route có tên gần giống không bị nhận nhầm', () {
      expect(
        AppRouter.onGenerateRoute(
          const RouteSettings(name: '/reset-password-help'),
        ),
        isNull,
      );
      expect(
        AppRouter.onGenerateRoute(
          const RouteSettings(name: '/reset-password/extra'),
        ),
        isNull,
      );
    });
  });
}

/// Chỉ để gọi `builder` mà không cần dựng cả cây widget.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
