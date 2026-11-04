/// Loại thông báo — cùng danh sách với enum `type` của backend.
enum NotificationType {
  system('SYSTEM', 'Hệ thống'),
  lesson('LESSON', 'Bài học'),
  exam('EXAM', 'Kỳ thi');

  const NotificationType(this.key, this.label);

  /// Giá trị `type` gửi và nhận từ API.
  final String key;
  final String label;

  /// Loại app chưa biết (server mới hơn app) hiện như thông báo hệ thống.
  static NotificationType fromKey(Object? key) =>
      values.firstWhere((type) => type.key == key, orElse: () => system);
}

/// Bộ lọc danh sách; [name] chính là giá trị `status` của API.
enum NotificationFilter {
  all('Tất cả'),
  unread('Chưa đọc'),
  read('Đã đọc');

  const NotificationFilter(this.label);

  final String label;
}

/// Một thông báo cá nhân của người đang đăng nhập.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromKey(json['type']),
      isRead: json['is_read'] as bool? ?? false,
      readAt: readAt == null ? null : DateTime.parse(readAt),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
}

/// Một trang thông báo trả về từ API.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) => NotificationPage(
        items: (json['data'] as List? ?? const [])
            .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        page: json['page'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  final List<AppNotification> items;
  final int page;
  final int totalPages;
  final int total;
}
