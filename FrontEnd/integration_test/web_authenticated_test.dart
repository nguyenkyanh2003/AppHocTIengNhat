@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web/web.dart' as web;

import 'package:apphoctiengnnhat/app/app.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';

/// Kiểm chứng các luồng **cần đăng nhập** trên trình duyệt thật.
///
/// Tài khoản truyền vào lúc chạy, không nằm trong repo:
///
/// ```
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/web_authenticated_test.dart -d chrome \
///   --dart-define=E2E_USERNAME=... --dart-define=E2E_PASSWORD=...
/// ```
///
/// Thiếu biến thì cả nhóm bị bỏ qua thay vì đỏ, để CI không phụ thuộc vào một
/// tài khoản có thật.
const _username = String.fromEnvironment('E2E_USERNAME');
const _password = String.fromEnvironment('E2E_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String hash() => web.window.location.hash;

  Future<void> openUrl(WidgetTester tester, String route) async {
    web.window.location.hash = '#$route';
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  }

  Future<void> bootApp(WidgetTester tester) async {
    await ApiClient().init();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  Future<void> signIn(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    expect(
      fields,
      findsAtLeastNWidgets(2),
      reason: 'màn đăng nhập phải có ô tên đăng nhập và mật khẩu',
    );

    await tester.enterText(fields.at(0), _username);
    await tester.enterText(fields.at(1), _password);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle(const Duration(seconds: 6));
  }

  group(
    'luồng cần đăng nhập',
    () {
      testWidgets('đăng nhập xong quay lại đúng trang định mở ban đầu', (
        tester,
      ) async {
        await bootApp(tester);

        // Người dùng bấm một link sâu khi chưa đăng nhập.
        await openUrl(tester, '/vocabulary');
        expect(hash(), contains('/login'));
        expect(hash(), contains('from='));

        await signIn(tester);

        // Đây là điểm mấu chốt: không rơi về trang chủ mà về đúng đích cũ.
        expect(
          hash(),
          contains('/vocabulary'),
          reason: 'phải quay lại đích ban đầu, không phải /home',
        );
        expect(hash(), isNot(contains('/login')));
      });

      testWidgets('tài khoản thường mở route quản trị thì bị chặn', (
        tester,
      ) async {
        await bootApp(tester);
        await openUrl(tester, '/admin/users');

        if (hash().contains('/login')) {
          await signIn(tester);
          await openUrl(tester, '/admin/users');
        }

        expect(hash(), contains('/forbidden'));
        expect(find.textContaining('quyền'), findsWidgets);
      });

      testWidgets('trang chi tiết mở được bằng URL và giữ nguyên khi đổi cỡ', (
        tester,
      ) async {
        await bootApp(tester);
        await openUrl(tester, '/vocabulary');
        if (hash().contains('/login')) await signIn(tester);

        // Rộng: phải có rail, không có thanh dưới.
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);

        // Hẹp: đổi sang thanh dưới mà không đổi URL, không văng lỗi.
        final urlTruocKhiThuNho = hash();
        tester.view.physicalSize = const Size(AppBreakpoints.rail - 1, 900);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(tester.takeException(), isNull);
        expect(
          hash(),
          urlTruocKhiThuNho,
          reason: 'đổi kích thước cửa sổ không được làm mất trang đang mở',
        );

        tester.view.reset();
      });
    },
    skip: _username.isEmpty || _password.isEmpty,
  );
}
