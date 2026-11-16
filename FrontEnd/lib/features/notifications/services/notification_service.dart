import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/notification.dart';

/// Thông báo cá nhân của người đang đăng nhập. Không đặt `cache`: trạng thái
/// đọc đổi liên tục, bản lưu ngoại tuyến sẽ hiện sai. Lỗi được ném ra để màn
/// hình báo lỗi, không biến thành "không có thông báo".
class NotificationService {
  NotificationService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

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
    final result = Paged.fromJson(await _apiClient.get('/notifications?$query'), AppNotification.fromJson);
    return NotificationPage(items: result.items, page: result.page, totalPages: result.totalPages, total: result.total);
  }

  /// Đánh dấu đã đọc; đọc lại một thông báo đã đọc vẫn thành công.
  Future<AppNotification> markAsRead(String id) async =>
      objectOf(await _apiClient.put('/notifications/read/$id', {}), AppNotification.fromJson);

  /// Số thông báo vừa chuyển sang đã đọc.
  Future<int> markAllAsRead() async =>
      objectOf(await _apiClient.put('/notifications/read-all', {}), (json) => json['updated'] as int? ?? 0);

  Future<void> deleteNotification(String id) => _apiClient.delete('/notifications/$id');

  Future<int> unreadCount() async =>
      objectOf(await _apiClient.get('/notifications/count/unread'), (json) => json['unread_count'] as int? ?? 0);
}
