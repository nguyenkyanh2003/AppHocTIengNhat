@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web/web.dart' as web;

import 'package:apphoctiengnnhat/app/app.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';

/// Kiểm chứng điều hướng trên **trình duyệt thật**.
///
/// Những gì chỉ có trên web mới lộ ra ở đây: thanh địa chỉ có đổi theo trang
/// không, dán một URL vào có mở đúng trang không, nút Back của trình duyệt có
/// đi lùi đúng không, và link đặt lại mật khẩu trong email có mở được không.
/// Test widget không trả lời được câu nào trong số đó.
///
/// Bộ này chạy khi **chưa đăng nhập** — không cần tài khoản, và cũng chính là
/// đường mà mọi người dùng mới đi vào.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String hash() => web.window.location.hash;

  /// Dán một URL vào thanh địa chỉ, đúng như người dùng mở link được gửi.
  ///
  /// Đổi `location.hash` sinh ra sự kiện lịch sử y hệt lúc gõ tay, nên
  /// `GoRouter` phản ứng đúng như khi tải trang.
  Future<void> openUrl(WidgetTester tester, String route) async {
    web.window.location.hash = '#$route';
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  }

  Future<void> bootApp(WidgetTester tester) async {
    await ApiClient().init();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  group('điều hướng bằng URL khi chưa đăng nhập', () {
    testWidgets('ứng dụng khởi động được trong trình duyệt', (tester) async {
      await bootApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
      // Chưa đăng nhập thì phải dừng ở màn đăng nhập, không phải trang chủ.
      expect(hash(), contains('/login'));
    });

    testWidgets('thanh địa chỉ đổi theo trang đang mở', (tester) async {
      await bootApp(tester);
      await openUrl(tester, '/register');
      expect(hash(), contains('/register'));
    });

    testWidgets('mở link cần đăng nhập thì bị chặn và nhớ đích ban đầu', (
      tester,
    ) async {
      await bootApp(tester);
      await openUrl(tester, '/vocabulary');

      expect(hash(), contains('/login'));
      expect(
        hash(),
        contains('from='),
        reason: 'phải mang theo đích ban đầu để quay lại sau khi đăng nhập',
      );
      expect(Uri.decodeComponent(hash()), contains('/vocabulary'));
    });

    testWidgets('link đặt lại mật khẩu trong email mở đúng màn', (
      tester,
    ) async {
      // Backend dựng link dạng `<base>/#/reset-password?token=...`; đây là
      // ràng buộc buộc dự án phải giữ hash URL.
      await bootApp(tester);
      await openUrl(tester, '/reset-password?token=e2e-token-gia');

      expect(hash(), contains('/reset-password'));
      expect(hash(), contains('token=e2e-token-gia'));
      expect(find.textContaining('mật khẩu'), findsWidgets);
    });

    testWidgets('URL lạ khi chưa đăng nhập bị chặn về login, không lộ route', (
      tester,
    ) async {
      // Guard đăng nhập chạy **trước** bộ bắt lỗi route, nên người chưa đăng
      // nhập gõ bừa một đường dẫn sẽ về màn đăng nhập chứ không thấy trang
      // "không tìm thấy" — cũng có nghĩa là không suy ra được route nào có
      // thật. Trang lỗi 404 chỉ dành cho người đã đăng nhập.
      await bootApp(tester);
      await openUrl(tester, '/khong-ton-tai-dau-ca');

      expect(hash(), contains('/login'));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('nút Back của trình duyệt đi lùi đúng', (tester) async {
      await bootApp(tester);

      await openUrl(tester, '/register');
      expect(hash(), contains('/register'));

      web.window.history.back();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(hash(), isNot(contains('/register')));

      web.window.history.forward();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(hash(), contains('/register'));
    });
  });

  group('bố cục trên trình duyệt', () {
    testWidgets('màn đăng nhập không tràn ở các bề rộng đã chốt', (
      tester,
    ) async {
      await bootApp(tester);

      for (final width in [360.0, 599.0, 601.0, 1024.0, 1440.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'tràn bố cục ở bề rộng $width',
        );
      }
      tester.view.reset();
    });
  });
}
