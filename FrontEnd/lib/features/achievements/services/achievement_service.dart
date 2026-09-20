import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
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
      debugPrint('Error fetching achievements: $e');
      return [];
    }
  }

  // Get user's achievements with progress
  Future<Map<String, dynamic>?> getMyAchievements() async {
    try {
      final response = await _apiClient.get('/achievement/my-achievements');
      return response;
    } catch (e) {
      debugPrint('Error fetching user achievements: $e');
      return null;
    }
  }

  // Get achievements by category
  Future<Map<String, dynamic>?> getAchievementsByCategory(
      String category) async {
    try {
      final response = await _apiClient.get('/achievement/category/$category');
      return response;
    } catch (e) {
      debugPrint('Error fetching category achievements: $e');
      return null;
    }
  }

  // Update achievement progress
  // `POST /achievement/update-progress` đã bị gỡ khỏi server: tiến độ thành
  // tích do server tự xác minh, không nhận lời khai từ client.

  // Get achievement statistics
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await _apiClient.get('/achievement/stats');
      return response;
    } catch (e) {
      debugPrint('Error fetching achievement stats: $e');
      return null;
    }
  }

  // Create achievement (admin)
  Future<Achievement?> createAchievement(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/achievement/create', data);
      return Achievement.fromJson(response);
    } catch (e) {
      debugPrint('Error creating achievement: $e');
      return null;
    }
  }
}
