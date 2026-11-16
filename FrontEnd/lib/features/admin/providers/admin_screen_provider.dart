import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';

/// Nền chung của provider các màn quản trị.
///
/// Mỗi màn tạo provider của riêng nó và huỷ khi rời màn, nên dữ liệu quản trị
/// không sống qua lần đăng xuất; phản hồi về sau khi màn đã đóng bị bỏ qua.
abstract class AdminScreenProvider extends ChangeNotifier {
  bool _disposed = false;

  @protected
  bool get disposed => _disposed;

  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  /// Chạy một thao tác ghi. Thành công thì chạy [refresh] để màn khớp server;
  /// trả `null` khi xong, ngược lại là câu báo lỗi để màn hiện tại chỗ.
  @protected
  Future<String?> write(Future<void> Function() action, {Future<void> Function()? refresh}) async {
    final result = await ViewState.guard(action);
    if (result.hasData && !_disposed) await refresh?.call();
    return result.errorOrNull;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
