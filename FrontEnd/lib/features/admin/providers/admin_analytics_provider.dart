import '../../../core/state/view_state.dart';
import '../models/admin_analytics.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Số liệu hoạt động theo kỳ. Đổi kỳ là tải lại; phản hồi của kỳ cũ về muộn bị bỏ.
class AdminAnalyticsProvider extends AdminScreenProvider {
  AdminAnalyticsProvider({AdminService? service}) : _service = service ?? AdminService();

  static const periods = {'7d': '7 ngày', '30d': '30 ngày', '90d': '90 ngày'};

  final AdminService _service;
  ViewState<AdminAnalytics> _analytics = const ViewState.idle();
  String _period = '7d';
  int _generation = 0;

  ViewState<AdminAnalytics> get analytics => _analytics;
  String get period => _period;

  Future<void> selectPeriod(String period) {
    _period = period;
    return load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    _analytics = const ViewState.loading();
    notify();
    final result = await ViewState.guard(() => _service.analytics(period: _period));
    if (generation != _generation) return;
    _analytics = result;
    notify();
  }
}
