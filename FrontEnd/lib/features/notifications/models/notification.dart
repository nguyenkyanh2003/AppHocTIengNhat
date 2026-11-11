/// Loại thông báo — cùng danh sách với enum `type` của backend.
enum NotificationType {
  system('SYSTEM', 'Hệ thống'),
  lesson('LESSON', 'Bài học'),
  exam('EXAM', 'Kỳ thi'),

  /// Server tự tạo khi cấp huy hiệu; admin không gửi được loại này.
  achievement('ACHIEVEMENT', 'Thành tích');

  const NotificationType(this.key, this.label);

  /// Giá trị `type` gửi và nhận từ API.
  final String key;
  final String label;

  /// Loại admin được chọn khi gửi tay (backend chặn các loại còn lại).
  static const sendable = [system, lesson, exam];

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
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    final data = json['data'];
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromKey(json['type']),
      isRead: json['is_read'] as bool? ?? false,
      readAt: readAt == null ? null : DateTime.parse(readAt),
      createdAt: DateTime.parse(json['created_at'] as String),
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Dữ liệu kèm theo; thông báo huy hiệu có `achievement_id`, `name`, `icon`, `rarity`, `xp`.
  final Map<String, dynamic> data;

  /// Tên huy hiệu, chỉ có ở thông báo huy hiệu.
  String? get badgeName => _text('name');

  /// Biểu tượng (emoji) của huy hiệu, chỉ có ở thông báo huy hiệu.
  String? get badgeIcon => _text('icon');

  String? _text(String key) {
    final value = data[key];
    return value is String && value.isNotEmpty ? value : null;
  }
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
