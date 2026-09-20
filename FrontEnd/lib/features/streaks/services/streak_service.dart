import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/user_streak.dart';

class StreakService {
  final ApiClient _apiClient = ApiClient();

  // Lấy thông tin streak của người dùng hiện tại
  Future<UserStreak?> getMyStreak() async {
    try {
      final response = await _apiClient.get('/streak/my-streak');
      if (response != null) {
        return UserStreak.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi lấy streak: $e');
      return null;
    }
  }

  // `POST /streak/add-xp` đã bị gỡ khỏi server: client không tự cộng XP
  // được nữa. XP do server cấp khi chấm xong bài (spec streak §3.1).

  // Lấy lịch sử XP
  Future<List<XPHistory>> getXPHistory() async {
    try {
      final response = await _apiClient.get('/streak/xp-history');
      if (response != null && response is List) {
        return response.map((item) => XPHistory.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi khi lấy lịch sử XP: $e');
      return [];
    }
  }

  // Lấy bảng xếp hạng
  Future<Map<String, dynamic>?> getLeaderboard({
    String period = 'all',
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/streak/leaderboard?period=$period&limit=$limit',
      );
      return response;
    } catch (e) {
      debugPrint('Lỗi khi lấy bảng xếp hạng: $e');
      return null;
    }
  }
}
