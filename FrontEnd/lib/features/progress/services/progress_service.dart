import '../../../core/network/api_client.dart';
import '../models/dashboard.dart';

/// Lỗi được ném lên chứ không đổi thành rỗng: màn hình cần phân biệt "chưa có dữ
/// liệu" với "không tải được".
class ProgressService {
  ProgressService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardStats> getDashboardStats() async {
    final response = await _apiClient.get('/progress/dashboard/stats');
    return DashboardStats.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<TimelineData>> getTimeline({String period = 'week'}) async {
    final response =
        await _apiClient.get('/progress/dashboard/timeline?period=$period');
    return _listOf(response, TimelineData.fromJson);
  }

  Future<List<HeatmapData>> getHeatmap({int? year}) async {
    final yearParam = year ?? DateTime.now().year;
    final response =
        await _apiClient.get('/progress/dashboard/heatmap?year=$yearParam');
    return _listOf(response, HeatmapData.fromJson);
  }

  Future<DashboardBreakdown> getBreakdown() async {
    final response = await _apiClient.get('/progress/dashboard/breakdown');
    return DashboardBreakdown.fromJson(
        Map<String, dynamic>.from(response as Map));
  }

  List<T> _listOf<T>(dynamic response, T Function(Map<String, dynamic>) parse) {
    if (response is! List) return const [];
    return response
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
