import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/dashboard.dart';

/// Lỗi được ném lên chứ không đổi thành rỗng: màn hình cần phân biệt "chưa có dữ
/// liệu" với "không tải được".
class ProgressService {
  ProgressService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<DashboardStats> getDashboardStats() async =>
      objectOf(await _client.get('/progress/dashboard/stats'), DashboardStats.fromJson);

  Future<List<TimelineData>> getTimeline({String period = 'week'}) async =>
      listOf(await _client.get('/progress/dashboard/timeline?period=$period'), TimelineData.fromJson);

  Future<List<HeatmapData>> getHeatmap({int? year}) async => listOf(
        await _client.get('/progress/dashboard/heatmap?year=${year ?? DateTime.now().year}'),
        HeatmapData.fromJson,
      );

  Future<DashboardBreakdown> getBreakdown() async =>
      objectOf(await _client.get('/progress/dashboard/breakdown'), DashboardBreakdown.fromJson);
}
