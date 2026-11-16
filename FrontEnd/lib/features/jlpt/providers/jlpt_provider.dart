import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/jlpt_models.dart';
import '../services/jlpt_service.dart';

/// Danh sách đề luyện thi, lọc theo cấp độ, tải thêm khi cuộn.
class JLPTProvider extends ChangeNotifier {
  JLPTProvider({JLPTService? service}) : _service = service ?? JLPTService();

  final JLPTService _service;
  late final _exams = PagedList<JLPTExamBrief>(onChanged: _notify);
  String? _level;
  bool _disposed = false;

  ViewState<List<JLPTExamBrief>> get exams => _exams.state;
  bool get hasMore => _exams.hasMore;
  bool get isLoadingMore => _exams.isLoadingMore;
  String? get loadMoreError => _exams.loadMoreError;
  String? get level => _level;

  /// Tải lại từ trang đầu; [level] `null` là mọi cấp độ.
  Future<void> loadExams({String? level}) {
    _level = level;
    return _exams.load((page) => _service.list(level: level, page: page));
  }

  Future<void> reload() => _exams.reload();

  Future<void> loadMore() => _exams.loadMore();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
