import '../../../core/state/view_state.dart';
import '../models/admin_dashboard_summary.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Số liệu tổng quan của bảng điều khiển quản trị.
class AdminDashboardProvider extends AdminScreenProvider {
  AdminDashboardProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;
  ViewState<AdminDashboardSummary> _summary = const ViewState.idle();

  ViewState<AdminDashboardSummary> get summary => _summary;

  /// Lần tải lại hỏng giữ số liệu đang hiện.
  Future<void> load() async {
    if (!_summary.hasData) {
      _summary = const ViewState.loading();
      notify();
    }
    final result = await ViewState.guard(_service.dashboard);
    if (result.hasData || !_summary.hasData) _summary = result;
    notify();
  }
}
