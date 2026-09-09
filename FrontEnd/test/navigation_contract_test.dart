import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:apphoctiengnnhat/app/router/app_router.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';

/// Gom mọi đường dẫn khai báo trong cây route, nối path cha vào path con.
Set<String> declaredPaths(List<RouteBase> routes, [String parent = '']) {
  final paths = <String>{};
  for (final route in routes) {
    var prefix = parent;
    if (route is GoRoute) {
      final base = parent == '/' ? '' : parent;
      prefix = route.path.startsWith('/') ? route.path : '$base/${route.path}';
      paths.add(prefix);
    }
    paths.addAll(declaredPaths(route.routes, prefix));
  }
  return paths;
}

void main() {
  group('contract đường dẫn', () {
    test('tập đường dẫn công khai giữ nguyên', () {
      expect(AppRouter.contract, {
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
        '/forbidden',
        '/home',
        '/study',
        '/review',
        '/progress',
        '/account',
        '/admin',
        '/lessons',
        '/lessons/:id',
        '/lessons/:id/study',
        '/vocabulary',
        '/vocabulary/study',
        '/vocabulary/:id',
        '/kanji',
        '/kanji/:id',
        '/grammar',
        '/grammar/:id',
        '/exercise',
        '/exercise/result/:resultId',
        '/exercise/:id',
        '/exercise-history',
        '/jlpt',
        '/jlpt-practice',
        '/jlpt/:examId/exam',
        '/news',
        '/news/:id',
        '/search',
        '/flashcards',
        '/flashcards/new',
        '/flashcards/:deckId',
        '/flashcards/:deckId/study',
        '/flashcards/:deckId/cards/new',
        '/flashcards/:deckId/cards/:cardId/edit',
        '/streak',
        '/achievements',
        '/notebook',
        '/notebook/new',
        '/notebook/:id',
        '/notebook/:id/edit',
        '/study-groups',
        '/study-groups/new',
        '/study-groups/:id',
        '/learning-history',
        '/statistics',
        '/goals',
        '/leaderboard',
        '/friend-leaderboard',
        '/profile',
        '/settings',
        '/notifications',
        '/notification-settings',
        '/offline-mode',
        '/export',
        '/payment',
        '/report',
        '/help',
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

    test('mọi trang công khai đều nằm trong contract', () {
      expect(AppRouter.contract.containsAll(AppRouter.publicPaths), isTrue);
    });

    test('contract khớp đúng cây route thật', () {
      // Không để `contract` thành một danh sách chép tay trôi khỏi code: so
      // trực tiếp với đường dẫn mà `GoRouter` đang khai báo.
      final router = AppRouter.create(AuthProvider());
      addTearDown(router.dispose);
      expect(
        declaredPaths(router.configuration.routes),
        AppRouter.contract,
      );
    });

    test('bốn lối vào từng chết nay đã có route', () {
      // `/news`, `/streak`, `/study-groups` và giao dịch được gọi từ menu
      // trang chủ nhưng trước đây không khai báo, nên rơi vào trang
      // "đang phát triển" dù màn hình có thật.
      expect(AppRouter.contract,
          containsAll(['/news', '/streak', '/study-groups']));
      expect(AppRouter.contract, contains('/admin/transactions'));
    });
  });

  group('redirect', () {
    String? redirect({
      required String location,
      String? from,
      bool sessionRestored = true,
      bool isAuthenticated = true,
      bool isAdmin = false,
    }) =>
        AppRouter.resolveRedirect(
          location: location,
          from: from,
          sessionRestored: sessionRestored,
          isAuthenticated: isAuthenticated,
          isAdmin: isAdmin,
        );

    test('chờ khôi phục phiên xong mới quyết định', () {
      expect(
        redirect(
          location: '/vocabulary',
          sessionRestored: false,
          isAuthenticated: false,
        ),
        '/splash?from=%2Fvocabulary',
      );
    });

    test('đang ở splash mà chưa khôi phục xong thì đứng yên', () {
      expect(
        redirect(location: '/splash', sessionRestored: false),
        isNull,
      );
    });

    test('khôi phục xong thì splash trả về đúng đích ban đầu', () {
      expect(
        redirect(location: '/splash', from: '/vocabulary'),
        '/vocabulary',
      );
    });

    test('khôi phục xong mà không có đích thì về trang chủ', () {
      expect(redirect(location: '/splash'), '/home');
    });

    test('chưa đăng nhập thì về login kèm đích ban đầu', () {
      expect(
        redirect(location: '/kanji', isAuthenticated: false),
        '/login?from=%2Fkanji',
      );
    });

    test('chưa đăng nhập vẫn vào được trang công khai', () {
      for (final path in AppRouter.publicPaths) {
        expect(
          redirect(location: path, isAuthenticated: false),
          isNull,
          reason: '$path phải mở được khi chưa đăng nhập',
        );
      }
    });

    test('đã đăng nhập thì không ở lại trang login', () {
      expect(redirect(location: '/login'), '/home');
    });

    test('đã đăng nhập vẫn vào được link đặt lại mật khẩu trong email', () {
      // Link trong email có dạng `<base>/#/reset-password?token=...`. Người
      // đang đăng nhập bấm vào đó vẫn phải tới được màn đặt lại mật khẩu.
      expect(redirect(location: '/reset-password'), isNull);
    });

    test('không phải admin thì route quản trị trả trang cấm truy cập', () {
      expect(redirect(location: '/admin/users'), '/forbidden');
      expect(redirect(location: '/admin'), '/forbidden');
    });

    test('admin vào được route quản trị', () {
      expect(redirect(location: '/admin/users', isAdmin: true), isNull);
    });

    test('trang thường không bị chuyển hướng', () {
      expect(redirect(location: '/vocabulary'), isNull);
      expect(redirect(location: '/vocabulary/abc123'), isNull);
    });
  });
}
