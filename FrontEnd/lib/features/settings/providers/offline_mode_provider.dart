import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/offline_cache.dart';
import '../services/offline_cache_service.dart';

/// Kết quả một thao tác trên bộ đệm, để màn hiện thông báo đúng màu.
typedef OfflineActionResult = ({bool success, String message});

/// Trạng thái bộ đệm ngoại tuyến và thao tác đang chạy trên nó.
class OfflineModeProvider extends ChangeNotifier {
  OfflineModeProvider({OfflineCacheService? service}) : _service = service ?? OfflineCacheService();

  final OfflineCacheService _service;

  ViewState<OfflineCacheStatus> _state = const ViewState.idle();
  bool _busy = false;
  bool _disposed = false;

  ViewState<OfflineCacheStatus> get state => _state;

  /// Đang tải, đồng bộ hay xoá: các nút thao tác khác tạm khoá.
  bool get isBusy => _busy;

  Future<void> load() async {
    _state = const ViewState.loading();
    _notify();
    await _refresh();
  }

  Future<void> setEnabled(bool enabled) async {
    await _service.setEnabled(enabled);
    await _refresh();
  }

  Future<OfflineActionResult> download(OfflineContentSelection selection) => _run(() async {
        final loaded = await _service.download(selection);
        return (success: true, message: 'Đã tải $loaded nhóm nội dung.');
      }, failure: 'Không thể tải dữ liệu');

  Future<OfflineActionResult> sync() => _run(() async {
        final synced = await _service.sync();
        return synced > 0
            ? (success: true, message: 'Đã đồng bộ $synced gói nội dung.')
            : (success: false, message: 'Không thể làm mới cache. Dữ liệu cũ vẫn được giữ.');
      }, failure: 'Không thể đồng bộ');

  Future<OfflineActionResult> clear() => _run(() async {
        await _service.clear();
        return (success: true, message: 'Đã xóa cache ngoại tuyến.');
      }, failure: 'Không thể xóa cache');

  /// Chạy một thao tác, khoá các nút trong lúc chạy và đọc lại trạng thái sau đó.
  Future<OfflineActionResult> _run(Future<OfflineActionResult> Function() action, {required String failure}) async {
    _busy = true;
    _notify();
    try {
      return await action();
    } catch (error) {
      return (success: false, message: '$failure: ${userMessageOf(error)}');
    } finally {
      await _refresh();
      _busy = false;
      _notify();
    }
  }

  Future<void> _refresh() async {
    _state = await ViewState.guard(_service.status);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
