import '../../../core/network/api_client.dart';
import '../models/achievement.dart';

/// Tiến độ huy hiệu do server tự đếm: client không gửi lên điều gì.
class AchievementService {
  AchievementService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<MyAchievements> getMyAchievements() async {
    final response = await _client.get('/achievement/my-achievements');
    return MyAchievements.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
