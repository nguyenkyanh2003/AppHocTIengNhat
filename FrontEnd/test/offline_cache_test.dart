import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/offline_cache.dart';

void main() {
  test('bản lưu dạng phản hồi cũ (v1) không bao giờ được đọc, và bị xoá khỏi máy', () async {
    SharedPreferences.setMockInitialValues({
      'offline_content_cache_v1': jsonEncode({
        '/lesson': {
          'cachedAt': '2026-09-01T00:00:00.000Z',
          'data': {'lessons': []},
        },
      }),
    });
    final cache = OfflineCache();

    expect(await cache.read('/lesson'), isNull);
    expect(await cache.keys(), isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('offline_content_cache_v1'), isFalse);
  });

  test('bản lưu mới đọc lại được đúng phản hồi đã ghi', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = OfflineCache();

    await cache.write('/lesson?page=1', {'data': [], 'total': 0});

    expect(await cache.read('/lesson?page=1'), {'data': [], 'total': 0});
    expect(OfflineCache.storageKey, isNot('offline_content_cache_v1'));
  });
}
