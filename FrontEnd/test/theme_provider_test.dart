import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/theme/theme_provider.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('lựa chọn đã lưu', () {
    test('chưa chọn bao giờ thì theo hệ thống', () async {
      expect(await ThemeProvider.loadSaved(), ThemeMode.system);
      expect(ThemeProvider().mode, ThemeMode.system);
    });

    for (final (saved, mode) in [('light', ThemeMode.light), ('dark', ThemeMode.dark), ('auto', ThemeMode.system)]) {
      test('đọc lại "$saved"', () async {
        SharedPreferences.setMockInitialValues({ThemeProvider.storageKey: saved});

        expect(await ThemeProvider.loadSaved(), mode);
      });
    }

    test('giá trị lạ trong kho thì theo hệ thống', () async {
      SharedPreferences.setMockInitialValues({ThemeProvider.storageKey: 'hong'});

      expect(await ThemeProvider.loadSaved(), ThemeMode.system);
    });

    test('chọn xong thì lần mở app sau đọc lại đúng lựa chọn đó', () async {
      final provider = ThemeProvider();

      await provider.setMode(ThemeMode.dark);

      expect(await ThemeProvider.loadSaved(), ThemeMode.dark);
    });

    test('đăng xuất không làm mất lựa chọn: đây là cài đặt của thiết bị', () async {
      await ThemeProvider().setMode(ThemeMode.dark);

      await ApiClient().clearAllData();

      expect(await ThemeProvider.loadSaved(), ThemeMode.dark);
    });
  });

  test('đổi lựa chọn báo cho người nghe, chọn lại giá trị cũ thì không', () async {
    final provider = ThemeProvider();
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setMode(ThemeMode.dark);
    await provider.setMode(ThemeMode.dark);

    expect(provider.mode, ThemeMode.dark);
    expect(notified, 1);
  });

  test('giá trị gửi lên server khớp enum settings.theme của backend', () {
    expect(ThemeProvider.valueOf(ThemeMode.light), 'light');
    expect(ThemeProvider.valueOf(ThemeMode.dark), 'dark');
    expect(ThemeProvider.valueOf(ThemeMode.system), 'auto');
  });

  group('cả ứng dụng theo lựa chọn', () {
    // Nội dung app xuất hiện sau khi nạp xong bản dịch, một nhịp sau pumpWidget.
    Future<void> pumpApp(WidgetTester tester, MyApp app) async {
      await tester.pumpWidget(app);
      await tester.pump();
    }

    Element appContent(WidgetTester tester) => tester.element(find.byWidgetPredicate((widget) => widget is Router));

    Brightness brightnessOf(WidgetTester tester) => Theme.of(appContent(tester)).brightness;

    ThemeProvider providerOf(WidgetTester tester) => appContent(tester).read<ThemeProvider>();

    // Theme đổi có hiệu ứng ngắn; pumpAndSettle không dùng được vì màn splash chạy animation.
    Future<void> themeSettles(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('khởi động đúng lựa chọn đã lưu', (tester) async {
      await pumpApp(tester, const MyApp(initialThemeMode: ThemeMode.dark));

      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
      expect(brightnessOf(tester), Brightness.dark);
    });

    testWidgets('đổi lựa chọn thì giao diện đổi ngay, không cần khởi động lại', (tester) async {
      await pumpApp(tester, const MyApp(initialThemeMode: ThemeMode.light));
      expect(brightnessOf(tester), Brightness.light);

      await providerOf(tester).setMode(ThemeMode.dark);
      await themeSettles(tester);
      expect(brightnessOf(tester), Brightness.dark);

      await providerOf(tester).setMode(ThemeMode.light);
      await themeSettles(tester);
      expect(brightnessOf(tester), Brightness.light);
    });

    testWidgets('chọn Tự động thì đi theo độ sáng của hệ thống', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpApp(tester, const MyApp());

      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
      expect(brightnessOf(tester), Brightness.dark);
    });
  });
}
