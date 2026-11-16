import 'package:flutter/foundation.dart';

import 'view_state.dart';

/// Chi tiết một mục theo id trong provider (bộ thẻ, ghi chú, bài tập...).
///
/// Mỗi lần [load] làm phản hồi của lần trước thành lỗi thời: về muộn cũng không
/// đè lên mục đang mở. [of] chỉ trả trạng thái khi đúng là của mục được hỏi —
/// màn mở mục mới không hiện nhầm một khung hình nội dung của mục cũ.
class DetailState<T> {
  DetailState({required String Function(T value) idOf, required VoidCallback onChanged})
      : _idOf = idOf,
        _onChanged = onChanged;

  final String Function(T value) _idOf;
  final VoidCallback _onChanged;

  ViewState<T> _state = const ViewState.idle();
  String? _id;
  int _generation = 0;

  ViewState<T> get state => _state;

  /// Trạng thái của mục [id]; mục khác đang giữ chỗ thì coi như đang tải.
  ViewState<T> of(String id) => id == _id ? _state : const ViewState.loading();

  Future<void> load(String id, Future<T> Function() fetch) async {
    final generation = ++_generation;
    _id = id;
    _state = const ViewState.loading();
    _onChanged();

    final result = await ViewState.guard(fetch);
    if (generation != _generation) return;
    _state = result;
    _onChanged();
  }

  /// Thay bằng bản server vừa trả sau một lần ghi, nếu đó là mục đang mở.
  void replace(T value) {
    if (_idOf(value) != _id) return;
    _generation++;
    _state = ViewState.data(value);
    _onChanged();
  }

  /// Mục đang mở vừa bị xoá thì về trạng thái chưa tải.
  void remove(String id) {
    if (id == _id) clear();
  }

  /// Về trạng thái chưa tải (đăng xuất). Phản hồi đang chạy bị bỏ.
  void clear() {
    _generation++;
    _id = null;
    _state = const ViewState.idle();
    _onChanged();
  }
}
