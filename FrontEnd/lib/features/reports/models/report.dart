/// Một báo cáo lỗi/góp ý người dùng gửi cho quản trị viên.
class Report {
  final String id;
  final String type;
  final String title;
  final String description;
  final String? relatedId;
  final String? relatedType;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.relatedId,
    this.relatedType,
    this.priority = 'medium',
    this.status = 'pending',
    required this.createdAt,
    this.adminResponse,
    this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'bug',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      adminResponse: json['admin_response'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }
}
