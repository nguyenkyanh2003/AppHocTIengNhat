import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
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
    final response = await _apiClient.get('/streak/my-streak');
    return UserStreak.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Cài đặt mục tiêu ngày và nhắc học.
  Future<StreakSettings> getSettings() async {
    final response = await _apiClient.get('/streak/settings');
    return StreakSettings.fromJson(Map<String, dynamic>.from(response['data'] as Map));
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
    return StreakSettings.fromJson(Map<String, dynamic>.from(response['data'] as Map));
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

  /// Một trang lịch sử XP, mới nhất trước. Lỗi được ném lên: người gọi (xuất
  /// dữ liệu) không được coi một trang lỗi là "hết lịch sử".
  Future<XpHistoryPage> getXpHistoryPage({String? cursor, int limit = maxPageSize}) async {
    final query = Uri(queryParameters: {
      'mode': 'page',
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    }).query;
    final response = await _apiClient.get('/streak/xp-history?$query');
    return XpHistoryPage(
      items: (response['data'] as List? ?? const [])
          .map((item) => XPHistory.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
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
      days: (response['data'] as List? ?? const [])
          .map((day) => StreakDay.fromJson(Map<String, dynamic>.from(day)))
          .toList(),
      nextCursor: response['next_cursor'] as String?,
      from: response['from'] as String,
      to: response['to'] as String,
    );
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
