import 'package:flutter/foundation.dart';

import '../network/api_envelope.dart';
import 'view_state.dart';

/// Một danh sách phân trang trong provider.
///
/// Trang đầu đi qua [ViewState] để `AsyncView` vẽ bốn nhánh; trang sau nối vào
/// danh sách đang có, lỗi của nó nằm riêng ở [loadMoreError] — danh sách không
/// bao giờ bị thay bằng vòng xoay hay màn lỗi khi chỉ tải thêm hỏng.
///
/// Mỗi lần [load] mới (đổi bộ lọc, gõ từ khoá) làm mọi phản hồi của lần trước
/// thành lỗi thời: chúng về muộn cũng không chạm vào trạng thái nào.
class PagedList<T> {
  PagedList({required VoidCallback onChanged}) : _onChanged = onChanged;

  final VoidCallback _onChanged;

  ViewState<List<T>> _state = const ViewState.idle();
  Future<Paged<T>> Function(int page)? _fetch;
  int _page = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  int _generation = 0;

  ViewState<List<T>> get state => _state;
  bool get hasMore => _state.hasData && _page < _totalPages;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;

  /// Tải lại từ trang đầu bằng [fetch]; [loadMore] về sau dùng cùng [fetch].
  Future<void> load(Future<Paged<T>> Function(int page) fetch) async {
    final generation = ++_generation;
    _fetch = fetch;
    _isLoadingMore = false;
    _loadMoreError = null;
    _state = const ViewState.loading();
    _onChanged();

    final result = await ViewState.guard(() => fetch(1));
    if (generation != _generation) return;
    _state = result.map(_accept);
    _onChanged();
  }

  /// Tải lại với đúng truy vấn đang hiện (kéo để làm mới, nút thử lại).
  Future<void> reload() async {
    final fetch = _fetch;
    if (fetch != null) await load(fetch);
  }

  Future<void> loadMore() async {
    final current = _state.valueOrNull;
    final fetch = _fetch;
    if (current == null || fetch == null || _isLoadingMore || !hasMore) return;
    final generation = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    _onChanged();

    final result = await ViewState.guard(() => fetch(_page + 1));
    if (generation != _generation) return;
    _isLoadingMore = false;
    final page = result.valueOrNull;
    if (page != null) {
      _state = ViewState.data([...current, ..._accept(page)]);
    } else {
      _loadMoreError = result.errorOrNull;
    }
    _onChanged();
  }

  /// Về trạng thái chưa tải (đăng xuất). Phản hồi đang chạy bị bỏ.
  void clear() {
    _generation++;
    _fetch = null;
    _state = const ViewState.idle();
    _isLoadingMore = false;
    _loadMoreError = null;
    _onChanged();
  }

  List<T> _accept(Paged<T> page) {
    _page = page.page;
    _totalPages = page.totalPages;
    return page.items;
  }
}
