import '../core/api_client.dart';
import '../models/dashboard.dart';

class ProgressService {
  final ApiClient _apiClient = ApiClient();

  // Lấy thống kê tổng quan
  Future<DashboardStats?> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/progress/dashboard/stats');
      if (response != null) {
        return DashboardStats.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dashboard stats: $e');
      return null;
    }
  }

  // Lấy timeline data
  Future<List<TimelineData>> getTimeline({String period = 'week'}) async {
    try {
      final response = await _apiClient.get(
        '/progress/dashboard/timeline?period=$period',
      );
      if (response != null && response is List) {
        return response.map((item) => TimelineData.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi khi lấy timeline: $e');
      return [];
    }
  }

  // Lấy heatmap data
  Future<List<HeatmapData>> getHeatmap({int? year}) async {
    try {
      final yearParam = year ?? DateTime.now().year;
      final response = await _apiClient.get(
        '/progress/dashboard/heatmap?year=$yearParam',
      );
      if (response != null && response is List) {
        return response.map((item) => HeatmapData.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi khi lấy heatmap: $e');
      return [];
    }
  }

  // Lấy breakdown data
  Future<DashboardBreakdown?> getBreakdown() async {
    try {
      final response = await _apiClient.get('/progress/dashboard/breakdown');
      if (response != null) {
        return DashboardBreakdown.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy breakdown: $e');
      return null;
    }
  }
}
