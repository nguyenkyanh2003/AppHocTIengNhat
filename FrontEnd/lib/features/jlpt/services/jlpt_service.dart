import '../../../core/network/api_client.dart';
import '../models/jlpt_models.dart';

class JLPTService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchExams({
    String? level,
    int? year,
    int? month,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (level != null && level.isNotEmpty) params['level'] = level;
    if (year != null) params['year'] = '$year';
    if (month != null) params['month'] = '$month';

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final resp = await _api.get('/jlpt?$query');
    final data = (resp['data'] as List<dynamic>? ?? [])
        .map((e) => JLPTExamBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    return {
      'total': resp['totalItems'] ?? 0,
      'pages': resp['totalPages'] ?? 1,
      'current': resp['currentPage'] ?? 1,
      'data': data,
    };
  }

  Future<JLPTExamDetail> fetchExamDetail(String id) async {
    final resp = await _api.get('/jlpt/$id');
    return JLPTExamDetail.fromJson(resp['data'] ?? resp);
  }

  Future<JLPTSubmitResult> submitExam(
      String id, Map<String, dynamic> payload) async {
    final resp = await _api.post('/jlpt/$id/submit', payload);
    return JLPTSubmitResult.fromJson(resp['ketQua'] ?? resp);
  }

  Future<List<JLPTQuestion>> fetchSolutions(String id) async {
    final resp = await _api.get('/jlpt/$id/solutions');
    final sections = resp['sections'] ?? {};
    final List<JLPTQuestion> all = [];
    all.addAll((sections['moji_goi'] as List<dynamic>? ?? [])
        .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>)));
    all.addAll((sections['bunpou'] as List<dynamic>? ?? [])
        .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>)));
    all.addAll((sections['dokkai'] as List<dynamic>? ?? [])
        .expand((g) => (g['questions'] as List<dynamic>? ?? []))
        .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>)));
    all.addAll((sections['choukai'] as List<dynamic>? ?? [])
        .expand((g) => (g['questions'] as List<dynamic>? ?? []))
        .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>)));
    return all;
  }

  Future<List<dynamic>> fetchPractice({
    required String type,
    String? level,
    int limit = 10,
  }) async {
    final params = <String, String>{'type': type, 'limit': '$limit'};
    if (level != null && level.isNotEmpty) params['level'] = level;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final resp = await _api.get('/jlpt/practice?$query');
    final list = resp['data'] as List<dynamic>? ?? [];
    // Trả raw map để provider phân loại theo type
    return list;
  }
}
