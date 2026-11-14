import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/localization/locale_provider.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/theme_provider.dart';
import 'package:apphoctiengnnhat/features/settings/screens/settings_screen.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';

/// Backend giả của `/settings`. Mọi tài khoản đang có `theme: 'light'` do giá trị mặc định của
/// schema, kể cả người chưa từng chọn; app không được lấy số đó đè lên lựa chọn trên máy.
class _SettingsBackend {
  final posted = <Map<String, dynamic>>[];

  MockClient get client => MockClient((request) async {
        if (request.method == 'POST') {
          posted.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(jsonEncode({'message': 'ok'}), 200, headers: _json);
        }
        return http.Response(
          jsonEncode({'data': {'notificationsEnabled': true, 'soundEnabled': true, 'vibrateEnabled': true, 'language': 'vi', 'theme': 'light'}}),
          200,
          headers: _json,
        );
      });

  static const _json = {'content-type': 'application/json; charset=utf-8'};
}

class _App extends StatelessWidget {
  const _App({required this.theme});

  final ThemeProvider theme;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [Locale('vi', 'VN')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SettingsScreen(),
          ),
        ),
      );
}

void main() {
  late _SettingsBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = _SettingsBackend();
  });

  Future<void> pumpSettings(WidgetTester tester, ThemeProvider theme) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      await tester.pumpWidget(_App(theme: theme));
      await tester.pumpAndSettle();
    }, () => backend.client);
  }

  Finder themeDropdown() => find.byWidgetPredicate((widget) => widget is DropdownButton<ThemeMode>);

  Brightness brightnessOf(WidgetTester tester) => Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

  testWidgets('hiện đúng lựa chọn trên máy, không lấy theme mặc định từ server đè lên', (tester) async {
    await pumpSettings(tester, ThemeProvider(ThemeMode.dark));

    expect(tester.widget<DropdownButton<ThemeMode>>(themeDropdown()).value, ThemeMode.dark);
    expect(brightnessOf(tester), Brightness.dark);
  });

  testWidgets('chưa chọn bao giờ thì ô chọn hiện Tự động, đúng như app đang chạy', (tester) async {
    await pumpSettings(tester, ThemeProvider());

    expect(tester.widget<DropdownButton<ThemeMode>>(themeDropdown()).value, ThemeMode.system);
    expect(find.text('Tự động'), findsOneWidget);
  });

  testWidgets('chọn Tối thì đổi ngay và nhớ lại, không cần bấm Lưu', (tester) async {
    await pumpSettings(tester, ThemeProvider(ThemeMode.light));
    expect(brightnessOf(tester), Brightness.light);

    await tester.ensureVisible(themeDropdown());
    await tester.pumpAndSettle();
    await tester.tap(themeDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối').last);
    await tester.pumpAndSettle();

    expect(brightnessOf(tester), Brightness.dark);
    expect(await ThemeProvider.loadSaved(), ThemeMode.dark);
    expect(backend.posted, isEmpty, reason: 'mất mạng không được làm hỏng việc đổi giao diện');
  });

  testWidgets('bấm Lưu gửi đúng lựa chọn đang dùng lên server', (tester) async {
    await pumpSettings(tester, ThemeProvider(ThemeMode.system));

    await http.runWithClient(() async {
      await tester.ensureVisible(find.text('Lưu cài đặt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu cài đặt'));
      await tester.pumpAndSettle();
    }, () => backend.client);

    expect(backend.posted.single['theme'], 'auto');
  });
}
