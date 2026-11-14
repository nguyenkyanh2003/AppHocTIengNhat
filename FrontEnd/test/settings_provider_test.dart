import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/providers/settings_provider.dart';
import 'package:apphoctiengnnhat/features/settings/services/settings_service.dart';

class _FakeSettings implements SettingsService {
  UserSettings stored = const UserSettings(soundEnabled: false, language: 'ja', theme: 'light');
  final saved = <UserSettings>[];
  Object? loadFailure;

  @override
  Future<UserSettings> getSettings() async {
    if (loadFailure != null) throw loadFailure!;
    return stored;
  }

  @override
  Future<void> saveSettings(UserSettings settings) async => saved.add(settings);
}

void main() {
  late _FakeSettings service;
  late SettingsProvider provider;

  setUp(() {
    service = _FakeSettings();
    provider = SettingsProvider(service: service);
  });

  test('chưa tải được cài đặt thật thì không sửa, không lưu đè bằng giá trị mặc định', () async {
    provider.update((current) => current.copyWith(vibrateEnabled: false));

    expect(provider.canSave, isFalse);
    expect(await provider.save(), isNotNull);
    expect(service.saved, isEmpty);
  });

  test('sửa trên máy rồi lưu: gửi đúng cài đặt đang hiện, kèm giao diện của máy', () async {
    expect(await provider.load(), isNull);
    expect(provider.settings.language, 'ja');

    provider.update((current) => current.copyWith(soundEnabled: true));
    expect(await provider.save(theme: 'dark'), isNull);

    final sent = service.saved.single;
    expect(sent.soundEnabled, isTrue);
    expect(sent.language, 'ja', reason: 'trường không sửa giữ nguyên giá trị của server');
    expect(sent.theme, 'dark');
  });

  test('tải lỗi thì trả câu báo lỗi, màn vẫn có giá trị mặc định để hiện', () async {
    service.loadFailure = ApiException('Mất kết nối');

    expect(await provider.load(), 'Mất kết nối');
    expect(provider.state.errorOrNull, 'Mất kết nối');
    expect(provider.settings.notificationsEnabled, isTrue);
    expect(provider.canSave, isFalse);
  });
}
