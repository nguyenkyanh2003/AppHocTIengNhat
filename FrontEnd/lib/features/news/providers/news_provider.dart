import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/news.dart';
import '../services/news_service.dart';

/// Danh sách tin (dùng chung cho trang tin và băng tin ở trang chủ) và bài đang đọc.
class NewsProvider extends ChangeNotifier {
  NewsProvider({NewsService? service}) : _service = service ?? NewsService();

  final NewsService _service;
  late final _list = PagedList<News>(onChanged: _notify);

  ViewState<News> _detail = const ViewState.idle();
  List<News> _related = const [];
  int _detailGeneration = 0;

  /// Tin yêu thích chỉ giữ trong phiên — chưa có API lưu.
  final Set<String> _bookmarks = {};
  bool _disposed = false;

  ViewState<List<News>> get listState => _list.state;

  /// Danh sách đang có (rỗng khi chưa tải xong), cho băng tin ở trang chủ.
  List<News> get newsList => _list.state.valueOrNull ?? const [];
  bool get hasMore => _list.hasMore;
  bool get isLoadingMore => _list.isLoadingMore;
  String? get loadMoreError => _list.loadMoreError;

  ViewState<News> get detailState => _detail;
  List<News> get related => _related;

  bool isBookmarked(String newsId) => _bookmarks.contains(newsId);
  List<News> get bookmarkedNews => newsList.where((news) => isBookmarked(news.id)).toList();

  Future<void> load({String? level, String? search}) =>
      _list.load((page) => _service.list(page: page, level: level, search: search));

  Future<void> loadMore() => _list.loadMore();

  /// Tải lại đúng bộ lọc đang hiện; chưa tải lần nào thì tải tin mới nhất.
  Future<void> refresh() => _list.state is ViewIdle ? load() : _list.reload();

  /// Bài hiện ngay khi tải xong; tin liên quan là phần phụ tải sau, hỏng thì khối
  /// đó ẩn đi chứ bài vẫn đọc được.
  Future<void> loadDetail(String id) async {
    final generation = ++_detailGeneration;
    _detail = const ViewState.loading();
    _related = const [];
    _notify();

    final detail = await ViewState.guard(() => _service.detail(id));
    if (generation != _detailGeneration) return;
    _detail = detail;
    _notify();
    if (!detail.hasData) return;

    final related = await ViewState.guard(() => _service.related(id));
    if (generation != _detailGeneration) return;
    _related = related.valueOrNull ?? const [];
    _notify();
  }

  void toggleBookmark(String newsId) {
    if (!_bookmarks.remove(newsId)) _bookmarks.add(newsId);
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
