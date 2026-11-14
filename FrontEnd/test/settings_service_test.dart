import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/services/settings_service.dart';

http.Response _json(Object body) =>
    http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('đọc cài đặt trong `data`; response thiếu `data` là lỗi rõ ràng', () async {
    final settings = await http.runWithClient(
      () => SettingsService().getSettings(),
      () => MockClient((_) async => _json({
            'data': {'notificationsEnabled': false, 'soundEnabled': true, 'vibrateEnabled': true, 'language': 'ja', 'theme': 'auto'},
          })),
    );
    expect((settings.notificationsEnabled, settings.language, settings.theme), (false, 'ja', 'auto'));

    await expectLater(
      http.runWithClient(() => SettingsService().getSettings(), () => MockClient((_) async => _json({'theme': 'dark'}))),
      throwsA(isA<ServerException>()),
    );
  });

  test('lưu gửi đủ năm cài đặt', () async {
    late Map<String, dynamic> sent;
    await http.runWithClient(
      () => SettingsService().saveSettings(const UserSettings(soundEnabled: false, theme: 'dark')),
      () => MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({'data': sent, 'message': 'ok'});
      }),
    );

    expect(sent, {'notificationsEnabled': true, 'soundEnabled': false, 'vibrateEnabled': true, 'language': 'vi', 'theme': 'dark'});
  });
}
