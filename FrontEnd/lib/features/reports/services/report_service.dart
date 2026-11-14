import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/report.dart';

class ReportService {
  ReportService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  Future<Report> create({
    required String type,
    required String title,
    required String description,
    String? relatedId,
    String? relatedType,
    String priority = 'medium',
  }) async {
    final response = await _client.post('/report/create', {
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      if (relatedId != null) 'related_id': relatedId,
      if (relatedType != null) 'related_type': relatedType,
    });
    return objectOf(response, Report.fromJson);
  }

  /// Báo cáo của người đang đăng nhập, mới nhất trước.
  Future<Paged<Report>> listMine({int page = 1, int limit = pageSize, String? status}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
    }).query;
    return Paged.fromJson(await _client.get('/report/my-reports?$query'), Report.fromJson);
  }
}
