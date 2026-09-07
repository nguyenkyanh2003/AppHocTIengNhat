import '../../../core/network/api_client.dart';
import '../models/vocabulary.dart';

/// Một trang từ vựng trả về từ API.
///
/// Trước đây service trả `Map<String, dynamic>` nên provider phải tự đoán tên
/// khoá và ép kiểu ở từng chỗ dùng.
class VocabularyPage {
  const VocabularyPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory VocabularyPage.fromJson(
    Map<String, dynamic> json, {
    int fallbackPage = 1,
  }) {
    return VocabularyPage(
      items: _parseList(json['data']),
      page: json['page'] as int? ?? fallbackPage,
      limit: json['limit'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  final List<Vocabulary> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

List<Vocabulary> _parseList(dynamic data) =>
    (data as List?)?.map((item) => Vocabulary.fromJson(item)).toList() ??
    const [];

class VocabularyService {
  final ApiClient _apiClient = ApiClient();

  /// Danh sách từ vựng có phân trang và bộ lọc.
  Future<VocabularyPage> getVocabularies({
    int page = 1,
    int limit = 20,
    String? level,
    String? studyStatus,
    String? sortBy,
  }) async {
    final endpoint = _endpoint('/vocabulary', {
      'page': '$page',
      'limit': '$limit',
      if (level != null && level.isNotEmpty) 'level': level,
      if (studyStatus != null && studyStatus.isNotEmpty)
        'studyStatus': studyStatus,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
    });

    final response = await _apiClient.get(endpoint, cache: true);
    return VocabularyPage.fromJson(
      Map<String, dynamic>.from(response as Map),
      fallbackPage: page,
    );
  }

  /// Tìm từ vựng theo từ khoá. Không có kết quả là danh sách rỗng, không phải lỗi.
  Future<List<Vocabulary>> searchVocabularies({
    required String keyword,
    String? level,
  }) async {
    final endpoint = _endpoint('/vocabulary/search', {
      'keyword': keyword,
      if (level != null && level.isNotEmpty) 'level': level,
    });

    final response = await _apiClient.get(endpoint, cache: true);
    return _parseList(response['data']);
  }

  Future<List<Vocabulary>> getVocabulariesByLesson(String lessonId) async {
    final response =
        await _apiClient.get('/vocabulary/lesson/$lessonId', cache: true);
    return _parseList(response['data']);
  }

  Future<Vocabulary> getVocabularyById(String id) async {
    final response = await _apiClient.get('/vocabulary/$id', cache: true);
    return Vocabulary.fromJson(response['data']);
  }

  /// Đánh dấu đã học: backend tạo tiến độ ôn tập ở box 1.
  Future<void> markAsLearned(String vocabularyId) async {
    await _apiClient.post('/vocabulary/$vocabularyId/mark-learned', {});
  }

  Future<void> unmarkAsLearned(String vocabularyId) async {
    await _apiClient.delete('/vocabulary/$vocabularyId/mark-learned');
  }

  String _endpoint(String path, Map<String, String> params) =>
      '$path?${Uri(queryParameters: params).query}';
}
