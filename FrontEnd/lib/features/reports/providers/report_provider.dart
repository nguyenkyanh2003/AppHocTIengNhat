import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/report.dart';
import '../services/report_service.dart';

/// Gửi báo cáo/góp ý và danh sách "Báo cáo của tôi".
class ReportProvider extends ChangeNotifier {
  ReportProvider({ReportService? service}) : _service = service ?? ReportService();

  final ReportService _service;
  late final _mine = PagedList<Report>(onChanged: _notify);
  bool _submitting = false;
  bool _disposed = false;

  ViewState<List<Report>> get myReports => _mine.state;
  bool get hasMore => _mine.hasMore;
  bool get isLoadingMore => _mine.isLoadingMore;
  String? get loadMoreError => _mine.loadMoreError;
  bool get isSubmitting => _submitting;

  Future<void> loadMyReports() => _mine.load((page) => _service.listMine(page: page));

  Future<void> loadMore() => _mine.loadMore();

  /// Gửi một báo cáo; trả `null` khi đã gửi, hoặc câu báo lỗi để màn hiện.
  /// Danh sách "Báo cáo của tôi" đã mở thì được làm mới để có bài vừa gửi.
  Future<String?> createReport({
    required String type,
    required String title,
    required String description,
    String? relatedId,
    String? relatedType,
    String priority = 'medium',
  }) async {
    if (_submitting) return 'Báo cáo trước vẫn đang được gửi.';
    _submitting = true;
    _notify();

    final result = await ViewState.guard(() => _service.create(
          type: type,
          title: title,
          description: description,
          relatedId: relatedId,
          relatedType: relatedType,
          priority: priority,
        ));
    _submitting = false;
    _notify();
    if (result.hasData && !_mine.state.isLoading && _mine.state is! ViewIdle) _mine.reload();
    return result.errorOrNull;
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
