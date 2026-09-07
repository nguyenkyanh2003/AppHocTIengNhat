import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/router/app_router.dart';

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
}
