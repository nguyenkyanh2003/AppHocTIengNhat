import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/models/password_policy.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/screens/change_password_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/login_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/register_screen.dart';
import 'package:apphoctiengnnhat/features/auth/widgets/reset_password_form.dart';

/// App thật tối thiểu: đủ bản dịch tiếng Việt và AuthProvider như `main.dart`.
Widget _app(String location, Widget screen) {
  final router = GoRouter(initialLocation: location, routes: [
    GoRoute(path: location, builder: (context, state) => screen),
    GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
    GoRoute(path: '/login', builder: (context, state) => const SizedBox()),
  ]);
  return ChangeNotifierProvider(
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

Future<void> _pump(WidgetTester tester, String location, Widget screen) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(location, screen));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

const _tooShort = 'Mật khẩu phải có ít nhất 8 ký tự';

void main() {
  test('một ngưỡng 8 ký tự, khớp backend; ba ngôn ngữ đều nói đúng số đó', () {
    expect(PasswordPolicy.minLength, 8);
    for (final (code, text) in [
      ('vi', 'Mật khẩu phải có ít nhất 8 ký tự'),
      ('en', 'Password must be at least 8 characters'),
      ('ja', 'パスワードは8文字以上必要です'),
    ]) {
      final l10n = AppLocalizations(Locale(code));
      expect(l10n.passwordMinLength(PasswordPolicy.minLength), text, reason: code);
      expect(l10n.passwordMinHint(PasswordPolicy.minLength), contains('8'), reason: code);
    }
  });

  testWidgets('đăng ký: báo trước yêu cầu 8 ký tự và chặn mật khẩu 7 ký tự', (tester) async {
    await _pump(tester, '/register', const RegisterScreen());
    expect(find.text('Tối thiểu 8 ký tự'), findsOneWidget);

    await tester.enterText(_field('Mật khẩu'), '1234567');
    await tester.enterText(_field('Xác nhận mật khẩu'), '1234567');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text(_tooShort), findsOneWidget);

    await tester.enterText(_field('Mật khẩu'), '12345678');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    // Đợi hiệu ứng mờ dần của dòng lỗi cũ chạy xong.
    await tester.pumpAndSettle();
    expect(find.text(_tooShort), findsNothing);
    expect(find.text('Mật khẩu không khớp'), findsOneWidget, reason: 'form đã được kiểm lại');
  });

  testWidgets('đăng nhập không kiểm độ dài: mật khẩu ngắn của tài khoản cũ vẫn được gửi đi', (tester) async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      await _pump(tester, '/login', const LoginScreen());
      await tester.enterText(find.byType(TextFormField).at(0), 'tai_khoan_cu');
      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.ensureVisible(find.text('Đăng Nhập'));
      await tester.tap(find.text('Đăng Nhập'));
      await tester.pumpAndSettle();
    }, () => MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode({'message': 'Mật khẩu không chính xác'}), 401,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));

    expect(find.textContaining('ít nhất'), findsNothing);
    expect(requests.map((r) => r.url.path), contains('/api/users/login'));
    expect(jsonDecode(requests.firstWhere((r) => r.url.path == '/api/users/login').body)['password'], 'abc');
  });

  testWidgets('đổi mật khẩu: bảng yêu cầu cập nhật ngay khi gõ, đủ 8 ký tự mới đạt', (tester) async {
    await _pump(tester, '/change-password', const ChangePasswordScreen());
    final requirement = find.widgetWithText(Row, 'Tối thiểu 8 ký tự');
    Finder met() => find.descendant(of: requirement, matching: find.byIcon(Icons.check_circle));

    await tester.enterText(_field('Mật khẩu mới'), '1234567');
    await tester.pump();
    expect(met(), findsNothing, reason: '7 ký tự chưa đạt');

    await tester.enterText(_field('Mật khẩu mới'), '12345678');
    await tester.pump();
    expect(met(), findsOneWidget);
  });

  testWidgets('đổi mật khẩu: mật khẩu mới 7 ký tự bị chặn với cùng thông điệp', (tester) async {
    await _pump(tester, '/change-password', const ChangePasswordScreen());

    await tester.enterText(_field('Mật khẩu hiện tại'), 'mat-khau-cu');
    await tester.enterText(_field('Mật khẩu mới'), '1234567');
    await tester.enterText(_field('Xác nhận mật khẩu mới'), '1234567');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text(_tooShort), findsOneWidget);
  });

  testWidgets('đặt lại mật khẩu: cùng ngưỡng và cùng thông điệp', (tester) async {
    String? submitted;
    await _pump(tester, '/reset', Scaffold(
      body: ResetPasswordForm(isSubmitting: false, onSubmit: (password) async => submitted = password),
    ));
    expect(find.text('Tối thiểu 8 ký tự'), findsOneWidget);

    await tester.enterText(_field('Mật khẩu mới'), '1234567');
    await tester.enterText(_field('Nhập lại mật khẩu mới'), '1234567');
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text(_tooShort), findsOneWidget);
    expect(submitted, isNull);
  });
}
