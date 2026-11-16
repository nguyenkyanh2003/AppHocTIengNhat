import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/achievement.dart';

/// Tiến độ huy hiệu do server tự đếm: client không gửi lên điều gì.
class AchievementService {
  AchievementService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<MyAchievements> getMyAchievements() async =>
      objectOf(await _client.get('/achievement/my-achievements'), MyAchievements.fromJson);
}
