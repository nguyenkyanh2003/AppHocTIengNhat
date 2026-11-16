import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/admin_report.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Báo cáo người học gửi lên: lọc theo trạng thái và loại phía server, số đếm
/// toàn hệ thống, phản hồi / đổi trạng thái / xoá.
class AdminReportsProvider extends AdminScreenProvider {
  AdminReportsProvider({AdminService? service}) : _service = service ?? AdminService();

  static const types = {
    'bug': 'Lỗi ứng dụng',
    'content': 'Nội dung',
    'suggestion': 'Góp ý',
    'other': 'Khác',
  };

  final AdminService _service;
  late final _reports = PagedList<AdminReport>(onChanged: notify);
  ViewState<AdminReportStats> _stats = const ViewState.idle();
  String? _status;
  String? _type;

  ViewState<List<AdminReport>> get reports => _reports.state;
  bool get hasMore => _reports.hasMore;
  bool get isLoadingMore => _reports.isLoadingMore;
  String? get loadMoreError => _reports.loadMoreError;
  bool get isRefreshing => _reports.isRefreshing;
  ViewState<AdminReportStats> get stats => _stats;

  /// `null` là mọi trạng thái / mọi loại.
  String? get status => _status;
  String? get type => _type;

  Future<void> load() => Future.wait([_loadReports(), _loadStats()]);

  Future<void> loadMore() => _reports.loadMore();

  Future<void> selectStatus(String? status) {
    _status = status;
    return _loadReports(keepCurrent: true);
  }

  Future<void> selectType(String? type) {
    _type = type;
    return _loadReports(keepCurrent: true);
  }

  /// Gửi phản hồi: báo cáo chuyển sang "đang xử lý", trừ khi đã xong.
  Future<String?> respond(AdminReport item, String response) {
    final status = item.report.status == 'resolved' ? 'resolved' : 'in_progress';
    return write(() => _service.updateReport(item.report.id, status: status, response: response), refresh: _refresh);
  }

  Future<String?> setStatus(AdminReport item, String status) =>
      write(() => _service.updateReport(item.report.id, status: status), refresh: _refresh);

  Future<String?> delete(AdminReport item) => write(() => _service.deleteReport(item.report.id), refresh: _refresh);

  Future<void> _loadReports({bool keepCurrent = false}) {
    final (status, type) = (_status, _type);
    return _reports.load((page) => _service.reports(page: page, status: status, type: type), keepCurrent: keepCurrent);
  }

  /// Số đếm chỉ là phần phụ: hỏng thì giữ số cũ, danh sách vẫn dùng được.
  Future<void> _loadStats() async {
    final result = await ViewState.guard(_service.reportStats);
    if (result.hasData || !_stats.hasData) _stats = result;
    notify();
  }

  Future<void> _refresh() => Future.wait([_reports.reload(keepCurrent: true), _loadStats()]);
}
