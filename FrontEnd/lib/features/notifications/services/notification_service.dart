import '../../../core/network/api_client.dart';
import '../models/notification.dart';

/// Thông báo cá nhân của người đang đăng nhập. Không đặt `cache`: trạng thái
/// đọc đổi liên tục, bản lưu ngoại tuyến sẽ hiện sai. Lỗi được ném ra để màn
/// hình báo lỗi, không biến thành "không có thông báo".
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  static const int pageSize = 20;

  /// [type] bỏ trống là mọi loại.
  Future<NotificationPage> getNotifications({
    int page = 1,
    NotificationFilter status = NotificationFilter.all,
    NotificationType? type,
  }) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$pageSize',
      'status': status.name,
      if (type != null) 'type': type.key,
    }).query;
    final response = await _apiClient.get('/notifications?$query');
    return NotificationPage.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Đánh dấu đã đọc; đọc lại một thông báo đã đọc vẫn thành công.
  Future<AppNotification> markAsRead(String id) async {
    final response = await _apiClient.put('/notifications/read/$id', {});
    return AppNotification.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Số thông báo vừa chuyển sang đã đọc.
  Future<int> markAllAsRead() async {
    final response = await _apiClient.put('/notifications/read-all', {});
    return response['data']['updated'] as int? ?? 0;
  }

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete('/notifications/$id');
  }

  Future<int> unreadCount() async {
    final response = await _apiClient.get('/notifications/count/unread');
    return response['data']['unread_count'] as int? ?? 0;
  }
}
