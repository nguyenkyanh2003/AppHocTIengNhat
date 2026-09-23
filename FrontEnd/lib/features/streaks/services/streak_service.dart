import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/user_streak.dart';

class StreakService {
  StreakService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

  /// Trang lớn nhất server cho phép ở hai đường phân trang.
  static const maxPageSize = 100;

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
