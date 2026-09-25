import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/screens/login_screen.dart';

/// Backend giả từ chối mọi lần đăng nhập, đúng hình dạng phản hồi 401 thật.
MockClient _rejectsLogin() => MockClient(
      (request) async => http.Response(
        jsonEncode({'message': 'Mật khẩu không chính xác'}),
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

Widget _loginApp() {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
    ],
  );

  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

Future<void> _submitWrongPassword(WidgetTester tester) async {
  await tester.pumpWidget(_loginApp());
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'demo_hocvien');
  await tester.enterText(find.byType(TextFormField).at(1), 'sai-mat-khau');
  // Form cuộn được và nút nằm dưới mép khung 800×600 của test: cuộn tới nút
  // trước, không thì cú chạm rơi ra ngoài và không có lần đăng nhập nào.
  await tester.ensureVisible(find.text('Đăng Nhập'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Đăng Nhập'));
  await tester.pumpAndSettle();
}

Finder _errorBanner() => find
    .ancestor(
      of: find.byIcon(Icons.error_outline),
      matching: find.byType(Container),
    )
    .first;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('chưa bấm đăng nhập thì không có khối lỗi chiếm chỗ',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(_loginApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    }, _rejectsLogin);
  });

  testWidgets('đăng nhập sai chỉ báo lỗi ở một chỗ, chữ không trùng màu nền',
      (tester) async {
    await http.runWithClient(() async {
      await _submitWrongPassword(tester);

      // Một cơ chế duy nhất: khối trong form, không kèm SnackBar.
      expect(find.byType(SnackBar), findsNothing);
      expect(_errorBanner(), findsOneWidget);

      final banner = tester.widget<Container>(_errorBanner());
      final background = (banner.decoration! as BoxDecoration).color;
      final message = tester.widget<Text>(
        find.descendant(of: _errorBanner(), matching: find.byType(Text)),
      );

      expect(message.data, isNotEmpty);
      expect(
        message.style?.color,
        isNot(background),
        reason: 'chữ trùng màu nền thì khối lỗi trông như một mảng đỏ rỗng',
      );
    }, _rejectsLogin);
  });
}
