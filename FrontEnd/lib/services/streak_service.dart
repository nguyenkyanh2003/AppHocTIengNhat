import '../core/api_client.dart';
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
      print('Lỗi khi lấy streak: $e');
      return null;
    }
  }

  // Thêm XP (tự động cập nhật streak khi có hoạt động học tập)
  Future<Map<String, dynamic>?> addXP(int amount, String reason) async {
    try {
      final response = await _apiClient.post('/streak/add-xp', {
        'amount': amount,
        'reason': reason,
      });
      return response;
    } catch (e) {
      print('Lỗi khi thêm XP: $e');
      return null;
    }
  }

  // Lấy lịch sử XP
  Future<List<XPHistory>> getXPHistory() async {
    try {
      final response = await _apiClient.get('/streak/xp-history');
      if (response != null && response is List) {
        return response.map((item) => XPHistory.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi khi lấy lịch sử XP: $e');
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
      print('Lỗi khi lấy bảng xếp hạng: $e');
      return null;
    }
  }
}
