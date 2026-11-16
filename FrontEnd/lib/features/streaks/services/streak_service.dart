import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/leaderboard.dart';
import '../models/streak_settings.dart';
import '../models/user_streak.dart';

class StreakService {
  StreakService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

  /// Trang lớn nhất server cho phép ở hai đường phân trang.
  static const maxPageSize = 100;

  /// Tóm tắt streak của người đang đăng nhập.
  ///
  /// Lỗi được ném lên chứ không đổi thành `null`: người gọi cần phân biệt "đồng
  /// bộ hỏng" với "không có dữ liệu" — bộ nhắc học không được coi một lần mất
  /// mạng là "hôm nay chưa học".
  Future<UserStreak> getMyStreak() async {
    return objectOf(await _apiClient.get('/streak/my-streak'), UserStreak.fromJson);
  }

  /// Cài đặt mục tiêu ngày và nhắc học.
  Future<StreakSettings> getSettings() async {
    return objectOf(await _apiClient.get('/streak/settings'), StreakSettings.fromJson);
  }

  /// Lưu những trường đã đổi; trường `null` giữ nguyên trên server.
  Future<StreakSettings> updateSettings({
    int? dailyGoalXp,
    bool? reminderEnabled,
    String? reminderTime,
  }) async {
    final response = await _apiClient.put('/streak/settings', {
      if (dailyGoalXp != null) 'daily_goal_xp': dailyGoalXp,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderTime != null) 'reminder_time': reminderTime,
    });
    return objectOf(response, StreakSettings.fromJson);
  }

  /// Toàn bộ lịch sử XP, mới nhất trước. XP chỉ do server cấp sau khi chấm bài.
  Future<List<XPHistory>> getXPHistory() async =>
      listOf(await _apiClient.get('/streak/xp-history'), XPHistory.fromJson);

  /// Một trang lịch sử XP, mới nhất trước. Lỗi được ném lên: người gọi (xuất
  /// dữ liệu) không được coi một trang lỗi là "hết lịch sử".
  Future<XpHistoryPage> getXpHistoryPage(
      {String? cursor, int limit = maxPageSize}) async {
    final query = Uri(queryParameters: {
      'mode': 'page',
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    }).query;
    final response = await _apiClient.get('/streak/xp-history?$query');
    return XpHistoryPage(
      items: listOf(response, XPHistory.fromJson),
      nextCursor: response['next_cursor'] as String?,
    );
  }

  /// Một trang lịch học trong khoảng ngày (tối đa 366 ngày). Bỏ trống khoảng
  /// thì server lấy 366 ngày tính tới hôm nay.
  Future<StreakDaysPage> getDays({
    String? from,
    String? to,
    String? cursor,
    int limit = maxPageSize,
  }) async {
    final query = Uri(queryParameters: {
      'limit': '$limit',
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (cursor != null) 'cursor': cursor,
    }).query;
    final response = await _apiClient.get('/streak/days?$query');
    return StreakDaysPage(
      days: listOf(response, StreakDay.fromJson),
      nextCursor: response['next_cursor'] as String?,
      from: response['from'] as String,
      to: response['to'] as String,
    );
  }

  /// Bảng xếp hạng theo kỳ (`all`, `month`, `week`) kèm hạng của người đang xem.
  Future<Leaderboard> getLeaderboard({String period = 'all', int limit = 50}) async {
    final query = Uri(queryParameters: {'period': period, 'limit': '$limit'}).query;
    return objectOf(await _apiClient.get('/streak/leaderboard?$query'), Leaderboard.fromJson);
  }
}
