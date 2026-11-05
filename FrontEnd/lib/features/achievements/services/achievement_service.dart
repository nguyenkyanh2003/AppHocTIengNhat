import '../../../core/network/api_client.dart';
import '../models/achievement.dart';

class AchievementService {
  final ApiClient _apiClient = ApiClient();

  // Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    final response = await _apiClient.get('/achievement/all');
    if (response != null && response is List) {
      return response.map((item) => Achievement.fromJson(item)).toList();
    }
    return [];
  }

  // Get user's achievements with progress
  Future<Map<String, dynamic>?> getMyAchievements() async {
    final response = await _apiClient.get('/achievement/my-achievements');
    return response;
  }

  // Get achievements by category
  Future<Map<String, dynamic>?> getAchievementsByCategory(
      String category) async {
    final response = await _apiClient.get('/achievement/category/$category');
    return response;
  }

  // Update achievement progress
  // `POST /achievement/update-progress` đã bị gỡ khỏi server: tiến độ thành
  // tích do server tự xác minh, không nhận lời khai từ client.

  // Get achievement statistics
  Future<Map<String, dynamic>?> getStats() async {
    final response = await _apiClient.get('/achievement/stats');
    return response;
  }
}
