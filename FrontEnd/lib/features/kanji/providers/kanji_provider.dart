import 'package:flutter/foundation.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/kanji.dart';
import '../services/kanji_service.dart';

/// Danh sách Kanji của màn tra cứu: lọc theo cấp độ, tải thêm khi cuộn, hoặc
/// kết quả tìm kiếm trong cấp độ đang chọn.
class KanjiProvider extends ChangeNotifier {
  KanjiProvider({KanjiService? service}) : _service = service ?? KanjiService();

  final KanjiService _service;
  late final _kanjis = PagedList<Kanji>(onChanged: _notify);
  String? _level;
  String _search = '';
  bool _disposed = false;

  ViewState<List<Kanji>> get kanjis => _kanjis.state;
  bool get hasMore => _kanjis.hasMore;
  bool get isLoadingMore => _kanjis.isLoadingMore;
  String? get loadMoreError => _kanjis.loadMoreError;
  String? get selectedLevel => _level;
  String get searchQuery => _search;

  /// Tải lại từ đầu với bộ lọc đang chọn.
  Future<void> loadKanjis() {
    final level = _level;
    final keyword = _search;
    return _kanjis.load((page) => keyword.isEmpty ? _service.list(page: page, level: level) : _searchPage(keyword, level));
  }

  Future<void> loadMore() => _kanjis.loadMore();

  Future<void> filterByLevel(String? level) {
    _level = level;
    return loadKanjis();
  }

  /// Từ khoá rỗng là quay về danh sách theo cấp độ.
  Future<void> search(String keyword) {
    _search = keyword.trim();
    return loadKanjis();
  }

  /// Kết quả tìm kiếm là một trang duy nhất (server trả tối đa 50 chữ).
  Future<Paged<Kanji>> _searchPage(String keyword, String? level) async {
    final items = await _service.search(keyword, level: level);
    return Paged(items: items, page: 1, limit: items.length, total: items.length, totalPages: 1);
  }

  /// Về trạng thái chưa tải (đăng xuất).
  void clear() {
    _kanjis.clear();
    _level = null;
    _search = '';
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
