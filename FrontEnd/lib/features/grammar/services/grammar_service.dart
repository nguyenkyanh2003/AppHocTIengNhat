import '../../../core/network/api_client.dart';
import '../models/grammar.dart';

class GrammarService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách ngữ pháp với phân trang và lọc
  Future<Map<String, dynamic>?> getGrammars({
    int page = 1,
    int limit = 10,
    String? level,
    String? search,
    String? lessonId,
    String? sortBy,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (level != null) 'level': level,
      if (search != null) 'search': search,
      if (lessonId != null) 'lessonID': lessonId,
      if (sortBy != null) 'sortBy': sortBy,
    };

    final response = await _apiClient.get(
      '/grammar?${_buildQueryString(params)}',
      cache: true,
    );
    return response;
  }

  /// Lấy chi tiết một ngữ pháp
  Future<Grammar?> getGrammarDetail(String grammarId) async {
    final response = await _apiClient.get('/grammar/$grammarId', cache: true);
    return Grammar.fromJson(response);
  }

  /// Lấy ngữ pháp theo cấp độ JLPT
  Future<Map<String, dynamic>?> getGrammarsByLevel(String level) async {
    final response = await _apiClient.get(
      '/grammar?level=$level',
      cache: true,
    );
    return response;
  }

  /// Lấy ngữ pháp theo bài học
  Future<List<Grammar>?> getGrammarsByLesson(String lessonId) async {
    final response = await _apiClient.get(
      '/grammar?lessonID=$lessonId',
      cache: true,
    );

    if (response != null && response is Map) {
      final data = response['data'] as List?;
      if (data != null) {
        return data.map((item) => Grammar.fromJson(item)).toList();
      }
    }
    return null;
  }

  /// Tìm kiếm ngữ pháp
  Future<Map<String, dynamic>?> searchGrammars(String query) async {
    final response = await _apiClient.get(
      '/grammar?search=$query',
    );
    return response;
  }

  String _buildQueryString(Map<String, dynamic> params) {
    final queryParts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        queryParts.add('$key=$value');
      }
    });
    return queryParts.join('&');
  }
}
