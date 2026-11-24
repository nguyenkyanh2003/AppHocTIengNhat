import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/providers/settings_provider.dart';
import 'package:apphoctiengnnhat/features/settings/services/settings_service.dart';

class _FakeSettings implements SettingsService {
  UserSettings stored = const UserSettings(soundEnabled: false, language: 'ja', theme: 'light');
  final saved = <UserSettings>[];
  int loads = 0;
  Object? loadFailure;
  Object? saveFailure;

  /// Lần lưu đang treo chờ test thả ra (để thử hai lần đổi liên tiếp).
  Completer<void>? holdSave;

  @override
  Future<UserSettings> getSettings() async {
    loads++;
    if (loadFailure != null) throw loadFailure!;
    return stored;
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    await holdSave?.future;
    if (saveFailure != null) throw saveFailure!;
    saved.add(settings);
  }
}

void main() {
  late _FakeSettings service;
  late SettingsProvider provider;

  setUp(() {
    service = _FakeSettings();
    provider = SettingsProvider(service: service);
  });

  test('tải theo tài khoản đang đăng nhập: đổi người thì tải lại, đăng xuất thì về mặc định', () async {
    provider.syncUser(null);
    expect(service.loads, 0);

    provider.syncUser('u1');
    await pumpEventQueue();
    expect(provider.settings.language, 'ja');

    provider.syncUser('u1');
    expect(service.loads, 1, reason: 'cùng người thì không tải lại');

    provider.syncUser(null);
    expect(provider.isLoaded, isFalse);
    expect(provider.settings.soundEnabled, isTrue, reason: 'đăng xuất: không giữ cài đặt của người trước');

    provider.syncUser('u2');
    await pumpEventQueue();
    expect(service.loads, 2);
  });

  test('chưa tải được cài đặt thật thì không đổi, không lưu đè bằng giá trị mặc định', () async {
    expect(await provider.change((current) => current.copyWith(vibrateEnabled: false)), isNotNull);
    expect(service.saved, isEmpty);
  });

  test('đổi là hiện ngay và lưu ngay, giữ nguyên các cài đặt khác', () async {
    await provider.load();

    final saving = provider.change((current) => current.copyWith(soundEnabled: true));
    expect(provider.settings.soundEnabled, isTrue, reason: 'công tắc đổi ngay, không chờ server');
    expect(await saving, isNull);

    expect(service.saved.single.soundEnabled, isTrue);
    expect(service.saved.single.language, 'ja');
  });

  test('lưu hỏng thì công tắc trở về như cũ và trả câu báo lỗi', () async {
    await provider.load();
    service.saveFailure = ApiException('Mất kết nối');

    expect(await provider.change((current) => current.copyWith(notificationsEnabled: false)), 'Mất kết nối');
    expect(provider.settings.notificationsEnabled, isTrue);
  });

  test('đổi hai công tắc liên tiếp: lưu lần lượt, lần lưu cuối mang đủ cả hai', () async {
    await provider.load();
    service.holdSave = Completer<void>();

    final first = provider.change((current) => current.copyWith(soundEnabled: true));
    final second = provider.change((current) => current.copyWith(vibrateEnabled: false));
    service.holdSave!.complete();
    expect(await first, isNull);
    expect(await second, isNull);

    final last = service.saved.last;
    expect((last.soundEnabled, last.vibrateEnabled), (true, false));
    expect(provider.isSaving, isFalse);
  });

  test('đăng xuất giữa lúc đang lưu: kết quả cũ không đè lên trạng thái mới', () async {
    provider.syncUser('u1');
    await pumpEventQueue();
    service.holdSave = Completer<void>();
    service.saveFailure = ApiException('Mất kết nối');

    final saving = provider.change((current) => current.copyWith(soundEnabled: true));
    provider.syncUser(null);
    service.holdSave!.complete();
    await saving;

    expect(provider.isLoaded, isFalse);
  });

  test('tải lỗi thì trả câu báo lỗi, vẫn có giá trị mặc định để hiện', () async {
    service.loadFailure = ApiException('Mất kết nối');

    expect(await provider.load(), 'Mất kết nối');
    expect(provider.state.errorOrNull, 'Mất kết nối');
    expect(provider.settings.notificationsEnabled, isTrue);
  });
}
