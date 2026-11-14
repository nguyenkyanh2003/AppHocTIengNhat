import '../../../core/network/api_client.dart';
import '../models/offline_cache.dart';

/// Bộ nhớ đệm ngoại tuyến. Bộ đệm nằm trong `ApiClient` vì mọi request đều đi qua
/// đó; service này chỉ cho màn cài đặt một mặt gọn, trả kiểu dữ liệu thay vì `Map`.
class OfflineCacheService {
  OfflineCacheService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<OfflineCacheStatus> status() async {
    final enabled = await _client.isOfflineModeEnabled();
    final info = await _client.offlineCacheInfo();
    return OfflineCacheStatus(
      enabled: enabled,
      items: info['items'] as int? ?? 0,
      bytes: info['bytes'] as int? ?? 0,
      lastSync: info['lastSync'] as DateTime?,
    );
  }

  Future<void> setEnabled(bool enabled) => _client.setOfflineModeEnabled(enabled);

  /// Tải các nhóm nội dung đã chọn rồi bật dùng bộ đệm; trả số nhóm đã tải.
  Future<int> download(OfflineContentSelection selection) async {
    final loaded = await _client.preloadOfflineContent(
      lessons: selection.lessons,
      vocabulary: selection.vocabulary,
      kanji: selection.kanji,
      grammar: selection.grammar,
    );
    await _client.setOfflineModeEnabled(true);
    return loaded;
  }

  /// Tải lại mọi gói đã có; trả số gói làm mới được.
  Future<int> sync() => _client.syncOfflineCache();

  Future<void> clear() => _client.clearOfflineCache();
}
