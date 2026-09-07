import '../../../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách thông báo
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');

    if (status != null && status.isNotEmpty) {
      params.add('status=$status');
    }

    final queryString = params.join('&');
    final response = await _apiClient.get('/notifications?$queryString');

    return {
      'totalItems': response['totalItems'] ?? 0,
      'totalPages': response['totalPages'] ?? 0,
      'currentPage': response['currentPage'] ?? page,
      'data': (response['data'] as List?)
              ?.map((item) => AppNotification.fromJson(item))
              .toList() ??
          [],
    };
  }

  /// Đánh dấu thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.put('/notifications/read/$notificationId', {});
  }

  /// Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.delete('/notifications/$notificationId');
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/count/unread');
      return response['unreadCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead() async {
    await _apiClient.put('/notifications/read-all', {});
  }
}
