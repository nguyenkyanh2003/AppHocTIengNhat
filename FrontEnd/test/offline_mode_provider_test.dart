import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/settings/models/offline_cache.dart';
import 'package:apphoctiengnnhat/features/settings/providers/offline_mode_provider.dart';
import 'package:apphoctiengnnhat/features/settings/services/offline_cache_service.dart';

class _FakeCache implements OfflineCacheService {
  bool enabled = false;
  int items = 0;
  int synced = 0;
  Object? downloadFailure;
  OfflineContentSelection? downloaded;

  @override
  Future<OfflineCacheStatus> status() async =>
      OfflineCacheStatus(enabled: enabled, items: items, bytes: items * 2048);

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<int> download(OfflineContentSelection selection) async {
    if (downloadFailure != null) throw downloadFailure!;
    downloaded = selection;
    items = 3;
    enabled = true;
    return 3;
  }

  @override
  Future<int> sync() async => synced;

  @override
  Future<void> clear() async => items = 0;
}

void main() {
  late _FakeCache cache;
  late OfflineModeProvider provider;

  setUp(() async {
    cache = _FakeCache();
    provider = OfflineModeProvider(service: cache);
    await provider.load();
  });

  test('tải nội dung đã chọn rồi đọc lại trạng thái bộ đệm', () async {
    final pending = provider.download(const OfflineContentSelection(kanji: false));
    expect(provider.isBusy, isTrue);

    final result = await pending;
    expect(result.success, isTrue);
    expect(cache.downloaded?.kanji, isFalse);
    expect(provider.isBusy, isFalse);
    expect(provider.state.valueOrNull?.items, 3);
    expect(provider.state.valueOrNull?.enabled, isTrue);
  });

  test('tải lỗi thì báo lỗi đọc được, trạng thái cũ vẫn còn', () async {
    cache.downloadFailure = ApiException('Máy chủ không phản hồi');

    final result = await provider.download(const OfflineContentSelection());
    expect(result.success, isFalse);
    expect(result.message, contains('Máy chủ không phản hồi'));
    expect(provider.state.valueOrNull?.isEmpty, isTrue);
  });

  test('đồng bộ không làm mới được gói nào thì báo là dữ liệu cũ vẫn giữ', () async {
    cache.items = 2;
    expect((await provider.sync()).success, isFalse);

    cache.synced = 2;
    expect((await provider.sync()).success, isTrue);
  });

  test('xoá bộ đệm và bật tắt dự phòng đều cập nhật trạng thái hiện trên màn', () async {
    cache.items = 4;
    await provider.setEnabled(true);
    expect(provider.state.valueOrNull?.enabled, isTrue);

    await provider.clear();
    expect(provider.state.valueOrNull?.isEmpty, isTrue);
  });
}
