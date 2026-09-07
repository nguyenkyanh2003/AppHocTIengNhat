import '../../../core/network/api_client.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'related_id': relatedId,
      'related_type': relatedType,
      'priority': priority,
    };
  }
}

class ReportService {
  final ApiClient _apiClient = ApiClient();

  /// Gửi báo cáo mới
  Future<Report?> createReport({
    required String type,
    required String title,
    required String description,
    String? relatedId,
    String? relatedType,
    String priority = 'medium',
  }) async {
    final data = {
      'type': type,
      'title': title,
      'description': description,
      'related_id': relatedId,
      'related_type': relatedType,
      'priority': priority,
    };
    final response = await _apiClient.post('/report/create', data);
    return Report.fromJson(Map<String, dynamic>.from(response['data']));
  }

  /// Lấy báo cáo của user hiện tại
  Future<List<Report>?> getMyReports({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get(
      '/report/my-reports?${Uri(queryParameters: params.map((key, value) => MapEntry(key, value.toString()))).query}',
    );
    final data = response is Map ? response['data'] as List? : null;
    return data
            ?.map((item) => Report.fromJson(Map<String, dynamic>.from(item)))
            .toList() ??
        [];
  }

  /// Xóa báo cáo
  Future<bool> deleteReport(String reportId) async {
    await _apiClient.delete('/report/$reportId');
    return true;
  }
}
