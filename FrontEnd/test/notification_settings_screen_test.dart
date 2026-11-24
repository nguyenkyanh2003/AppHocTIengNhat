import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/providers/settings_provider.dart';
import 'package:apphoctiengnnhat/features/settings/screens/notification_settings_screen.dart';
import 'package:apphoctiengnnhat/features/settings/services/alert_feedback.dart';
import 'package:apphoctiengnnhat/features/settings/services/settings_service.dart';

class _FakeSettings implements SettingsService {
  _FakeSettings(this.stored);

  UserSettings stored;
  final saved = <UserSettings>[];
  Object? saveFailure;

  @override
  Future<UserSettings> getSettings() async => stored;

  @override
  Future<void> saveSettings(UserSettings settings) async {
    if (saveFailure != null) throw saveFailure!;
    saved.add(settings);
  }
}

void main() {
  late _FakeSettings service;
  late List<String> feedback;

  Future<void> pumpScreen(WidgetTester tester, {UserSettings settings = const UserSettings()}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    service = _FakeSettings(settings);
    feedback = [];
    final provider = SettingsProvider(service: service);
    await provider.load();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        Provider.value(value: AlertFeedback(
          playSound: () async => feedback.add('âm báo'),
          vibrate: () async => feedback.add('rung'),
        )),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const NotificationSettingsScreen()),
    ));
    await tester.pumpAndSettle();
  }

  SwitchListTile switchOf(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));

  testWidgets('tắt Âm thanh: lưu ngay lên tài khoản, không có nút Lưu để quên bấm', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Lưu cài đặt'), findsNothing);

    await tester.tap(find.text('Âm thanh'));
    await tester.pumpAndSettle();

    expect(switchOf(tester, 'Âm thanh').value, isFalse);
    expect(service.saved.single.soundEnabled, isFalse);
    expect(service.saved.single.vibrateEnabled, isTrue);
  });

  testWidgets('tắt Nhận thông báo: âm thanh, rung và nút thử mờ đi nhưng giữ lựa chọn', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Nhận thông báo'));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo đang tắt'), findsOneWidget);
    expect(switchOf(tester, 'Âm thanh').onChanged, isNull);
    expect(switchOf(tester, 'Âm thanh').value, isTrue, reason: 'bật lại là như cũ');
    expect(switchOf(tester, 'Rung').onChanged, isNull);
    final tryButton = find.ancestor(of: find.text('Gửi thông báo thử'), matching: find.byWidgetPredicate((widget) => widget is OutlinedButton));
    expect(tester.widget<OutlinedButton>(tryButton).onPressed, isNull);
  });

  testWidgets('lưu hỏng: công tắc trở về như cũ và báo lỗi', (tester) async {
    await pumpScreen(tester);
    service.saveFailure = ApiException('Mất kết nối');

    await tester.tap(find.text('Rung'));
    await tester.pumpAndSettle();

    expect(switchOf(tester, 'Rung').value, isTrue);
    expect(find.text('Chưa lưu được cài đặt: Mất kết nối'), findsOneWidget);
  });

  testWidgets('Gửi thông báo thử: hiện lời báo mẫu, kêu và rung theo cài đặt', (tester) async {
    await pumpScreen(tester, settings: const UserSettings(vibrateEnabled: false));

    await tester.tap(find.text('Gửi thông báo thử'));
    await tester.pump();

    expect(find.text('Thông báo thử: tin mới sẽ hiện như thế này.'), findsOneWidget);
    expect(feedback, ['âm báo']);
  });

  testWidgets('nói rõ ba công tắc tác động tới những lời báo nào', (tester) async {
    await pumpScreen(tester);

    expect(find.text('• Bạn vừa nhận huy hiệu mới.'), findsOneWidget);
    expect(find.textContaining('nhắc học'), findsWidgets);
    expect(find.textContaining('Quản trị viên hoặc nhóm học'), findsOneWidget);
  });
}
