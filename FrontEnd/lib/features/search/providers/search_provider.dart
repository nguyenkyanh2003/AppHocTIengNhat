import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';

/// State của màn tìm kiếm: từ khoá đang có hiệu lực và kết quả của nó.
///
/// Gõ liên tục chỉ gửi một request, sau [debounce] kể từ lần gõ cuối. Mỗi lần
/// đổi từ khoá hay xoá ô đều tăng `_generation`, nên phản hồi của một lần tìm
/// đã bị bỏ — kể cả khi về muộn hơn lần tìm mới — không chạm được vào state.
class SearchProvider extends ChangeNotifier {
  SearchProvider({
    SearchService? service,
    this.debounce = const Duration(milliseconds: 300),
  }) : _service = service ?? SearchService();

  final SearchService _service;
  final Duration debounce;

  ViewState<List<SearchResult>> _results = const ViewState.idle();
  String _query = '';
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  ViewState<List<SearchResult>> get results => _results;

  /// Từ khoá đã cắt khoảng trắng; rỗng nghĩa là ô tìm đang trống.
  String get query => _query;

  /// Gọi mỗi lần nội dung ô tìm đổi. Thêm khoảng trắng không đổi từ khoá nên
  /// không tìm lại; ô chỉ còn khoảng trắng coi như vừa xoá.
  void updateQuery(String text) {
    final query = text.trim();
    if (query == _query) return;
    if (query.isEmpty) return clear();

    _timer?.cancel();
    _query = query;
    final generation = ++_generation;
    _timer = Timer(debounce, () => _search(generation));
    _notify();
  }

  /// Tìm lại ngay từ khoá hiện tại — cho nút "Thử lại".
  Future<void> retry() {
    if (_query.isEmpty) return Future.value();
    _timer?.cancel();
    return _search(++_generation);
  }

  /// Xoá ô: huỷ lần tìm đang chờ và bỏ phản hồi của lần tìm đang chạy.
  void clear() {
    _timer?.cancel();
    _generation++;
    _query = '';
    _results = const ViewState.idle();
    _notify();
  }

  Future<void> _search(int generation) async {
    final query = _query;
    _results = const ViewState.loading();
    _notify();

    final result = await ViewState.guard(() => _service.search(query));
    if (generation != _generation || _disposed) return;
    _results = result;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
