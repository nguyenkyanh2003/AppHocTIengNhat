import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/dashboard.dart';
import '../services/progress_service.dart';

/// Số liệu học tập dùng chung cho màn Tiến độ, Lịch sử học và Thống kê chi tiết.
class ProgressProvider with ChangeNotifier {
  ProgressProvider({ProgressService? service})
      : _service = service ?? ProgressService();

  final ProgressService _service;

  ViewState<ProgressDashboard> _dashboard = const ViewState.idle();
  String _selectedPeriod = 'week';
  bool _isChangingPeriod = false;

  /// Lượt đổi kỳ mới nhất: phản hồi của lượt cũ về muộn không được đè lên.
  int _periodRequest = 0;

  ViewState<ProgressDashboard> get dashboard => _dashboard;
  String get selectedPeriod => _selectedPeriod;
  bool get isChangingPeriod => _isChangingPeriod;
  bool get isLoading => _dashboard.isLoading;

  DashboardStats? get stats => _dashboard.valueOrNull?.stats;
  List<TimelineData> get timeline =>
      _dashboard.valueOrNull?.timeline ?? const [];
  List<HeatmapData> get heatmap => _dashboard.valueOrNull?.heatmap ?? const [];
  DashboardBreakdown? get breakdown => _dashboard.valueOrNull?.breakdown;

  /// Tải cả bốn phần cùng lúc. Lần tải lại hỏng thì giữ số liệu đang có: mất mạng
  /// một lần không được xoá trắng màn hình.
  Future<void> loadDashboardData() async {
    if (!_dashboard.hasData) {
      _dashboard = const ViewState.loading();
      notifyListeners();
    }

    final period = _selectedPeriod;
    final result = await ViewState.guard(() async {
      final parts = await Future.wait<Object?>([
        _service.getDashboardStats(),
        _service.getTimeline(period: period),
        _service.getHeatmap(),
        _service.getBreakdown(),
      ]);
      return ProgressDashboard(
        stats: parts[0] as DashboardStats,
        timeline: parts[1] as List<TimelineData>,
        heatmap: parts[2] as List<HeatmapData>,
        breakdown: parts[3] as DashboardBreakdown,
      );
    });

    if (result.hasData || !_dashboard.hasData) _dashboard = result;
    notifyListeners();
  }

  /// Đổi kỳ của biểu đồ. Trả `null` khi đổi được, ngược lại là câu báo lỗi; khi
  /// lỗi thì kỳ và số liệu cũ giữ nguyên để nút chọn không nói dối.
  Future<String?> changePeriod(String period) async {
    if (period == _selectedPeriod) return null;

    final request = ++_periodRequest;
    final previous = _selectedPeriod;
    _selectedPeriod = period;
    _isChangingPeriod = true;
    notifyListeners();

    final result =
        await ViewState.guard(() => _service.getTimeline(period: period));
    if (request != _periodRequest) return null;

    _isChangingPeriod = false;
    final current = _dashboard.valueOrNull;
    if (result is ViewData<List<TimelineData>>) {
      if (current != null) {
        _dashboard = ViewState.data(current.withTimeline(result.value));
      }
      notifyListeners();
      return null;
    }

    _selectedPeriod = previous;
    notifyListeners();
    return result.errorOrNull;
  }

  /// Xoá mọi trạng thái, dùng khi đăng xuất.
  void clear() {
    _periodRequest += 1;
    _dashboard = const ViewState.idle();
    _selectedPeriod = 'week';
    _isChangingPeriod = false;
    notifyListeners();
  }
}
