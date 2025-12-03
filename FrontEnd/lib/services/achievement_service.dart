import '../core/api_client.dart';
import '../models/achievement.dart';

class AchievementService {
  final ApiClient _apiClient = ApiClient();

  // Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _apiClient.get('/achievement/all');
      if (response != null && response is List) {
        return response.map((item) => Achievement.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  // Get user's achievements with progress
  Future<Map<String, dynamic>?> getMyAchievements() async {
    try {
      final response = await _apiClient.get('/achievement/my-achievements');
      return response;
    } catch (e) {
      print('Error fetching user achievements: $e');
      return null;
    }
  }

  // Get achievements by category
  Future<Map<String, dynamic>?> getAchievementsByCategory(String category) async {
    try {
      final response = await _apiClient.get('/achievement/category/$category');
      return response;
    } catch (e) {
      print('Error fetching category achievements: $e');
      return null;
    }
  }

  // Update achievement progress
  Future<UserAchievement?> updateProgress(String achievementId, int progress) async {
    try {
      final response = await _apiClient.post('/achievement/update-progress', {
        'achievement_id': achievementId,
        'progress': progress,
      });
      return UserAchievement.fromJson(response);
          return null;
    } catch (e) {
      print('Error updating achievement progress: $e');
      return null;
    }
  }

  // Get achievement statistics
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await _apiClient.get('/achievement/stats');
      return response;
    } catch (e) {
      print('Error fetching achievement stats: $e');
      return null;
    }
  }

  // Create achievement (admin)
  Future<Achievement?> createAchievement(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/achievement/create', data);
      return Achievement.fromJson(response);
          return null;
    } catch (e) {
      print('Error creating achievement: $e');
      return null;
    }
  }
}
