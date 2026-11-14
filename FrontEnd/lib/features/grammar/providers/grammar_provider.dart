import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/grammar.dart';
import '../services/grammar_service.dart';

/// Danh sách và chi tiết ngữ pháp.
class GrammarProvider extends ChangeNotifier {
  GrammarProvider({GrammarService? service}) : _service = service ?? GrammarService();

  final GrammarService _service;
  late final _list = PagedList<Grammar>(onChanged: _notify);
  ViewState<Grammar> _detail = const ViewState.idle();
  int _detailGeneration = 0;
  bool _disposed = false;

  ViewState<List<Grammar>> get listState => _list.state;
  ViewState<Grammar> get detailState => _detail;
  bool get hasMore => _list.hasMore;
  bool get isLoadingMore => _list.isLoadingMore;
  String? get loadMoreError => _list.loadMoreError;

  Future<void> load({String? level, String? search, GrammarSort sort = GrammarSort.title}) =>
      _list.load((page) => _service.list(page: page, level: level, search: search, sort: sort));

  /// Nối trang kế tiếp; danh sách đang có giữ nguyên trong lúc tải và khi lỗi.
  Future<void> loadMore() => _list.loadMore();

  Future<void> loadDetail(String id) async {
    final generation = ++_detailGeneration;
    _detail = const ViewState.loading();
    _notify();

    final result = await ViewState.guard(() => _service.detail(id));
    if (generation != _detailGeneration) return;
    _detail = result;
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
