import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/models/email_format.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/screens/forgot_password_screen.dart';
import 'package:apphoctiengnnhat/features/auth/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  final requested = <String>[];

  @override
  Future<void> forgotPassword(String email) async => requested.add(email);
}

void main() {
  group('EmailFormat', () {
    test('nhận địa chỉ server nhận: dấu +, gạch dưới, đuôi tên miền dài', () {
      for (final email in [
        'lan@gmail.com',
        'lan+jp@gmail.com',
        'nguyen_van_a@sis.hust.edu.vn',
        'an@hust.education',
        'thu@example.invalid',
      ]) {
        expect(EmailFormat.validate(email), isNull, reason: email);
      }
    });

    test('chặn lỗi gõ rõ ràng', () {
      for (final email in ['lan', 'lan@', 'lan@gmail', '@gmail.com', 'lan @gmail.com', 'lan@@gmail.com']) {
        expect(EmailFormat.validate(email), 'Email không hợp lệ', reason: email);
      }
    });

    test('ô trống thì nhắc nhập', () {
      expect(EmailFormat.validate(''), 'Vui lòng nhập email');
      expect(EmailFormat.validate('   '), 'Vui lòng nhập email');
      expect(EmailFormat.validate(null), 'Vui lòng nhập email');
    });
  });

  testWidgets('quên mật khẩu gửi được địa chỉ có dấu + và đuôi tên miền dài', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final service = _FakeAuthService();
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: service),
      child: MaterialApp(theme: AppTheme.lightTheme, home: const ForgotPasswordScreen()),
    ));

    await tester.enterText(find.byType(TextFormField), 'an+jp@hust.education');
    await tester.tap(find.text('Gửi email'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ'), findsNothing);
    expect(service.requested, ['an+jp@hust.education']);
  });
}
