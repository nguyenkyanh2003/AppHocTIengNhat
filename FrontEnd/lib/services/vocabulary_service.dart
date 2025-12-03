import '../core/api_client.dart';
import '../models/vocabulary.dart';

class VocabularyService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách từ vựng với phân trang và filter
  Future<Map<String, dynamic>> getVocabularies({
    int page = 1,
    int limit = 20,
    String? level,
  }) async {
    // Build query string
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');
    
    if (level != null && level.isNotEmpty) {
      params.add('level=$level');
    }

    final queryString = params.join('&');
    final response = await _apiClient.get('/vocabulary?$queryString');

    return {
      'totalItems': response['totalItems'] ?? 0,
      'totalPages': response['totalPages'] ?? 0,
      'currentPage': response['currentPage'] ?? page,
      'data': (response['data'] as List?)
              ?.map((item) => Vocabulary.fromJson(item))
              .toList() ??
          [],
    };
  }

  /// Tìm kiếm từ vựng
  Future<List<Vocabulary>> searchVocabularies({
    required String keyword,
    String? level,
  }) async {
    // Build query string
    final params = <String>[];
    params.add('keyword=$keyword');
    
    if (level != null && level.isNotEmpty) {
      params.add('level=$level');
    }

    final queryString = params.join('&');
    final response = await _apiClient.get('/vocabulary/search?$queryString');

    return (response['data'] as List?)
            ?.map((item) => Vocabulary.fromJson(item))
            .toList() ??
        [];
  }

  /// Lấy từ vựng theo bài học
  Future<List<Vocabulary>> getVocabulariesByLesson(String lessonId) async {
    final response = await _apiClient.get('/vocabulary/lesson/$lessonId');

    return (response['data'] as List?)
            ?.map((item) => Vocabulary.fromJson(item))
            .toList() ??
        [];
  }

  /// Lấy từ vựng theo level
  Future<List<Vocabulary>> getVocabulariesByLevel(String level) async {
    final response = await _apiClient.get('/vocabulary/level/$level');

    return (response['data'] as List?)
            ?.map((item) => Vocabulary.fromJson(item))
            .toList() ??
        [];
  }

  /// Lấy chi tiết một từ vựng
  Future<Vocabulary> getVocabularyById(String id) async {
    final response = await _apiClient.get('/vocabulary/$id');
    return Vocabulary.fromJson(response);
  }

  /// Tạo từ vựng mới (Admin)
  Future<Vocabulary> createVocabulary(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/vocabulary', data);
    return Vocabulary.fromJson(response['data']);
  }

  /// Cập nhật từ vựng (Admin)
  Future<Vocabulary> updateVocabulary(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put('/vocabulary/$id', data);
    return Vocabulary.fromJson(response['data']);
  }

  /// Xóa từ vựng (Admin)
  Future<void> deleteVocabulary(String id) async {
    await _apiClient.delete('/vocabulary/$id');
  }

  /// Lấy thống kê từ vựng
  Future<Map<String, dynamic>> getVocabularyStats() async {
    final response = await _apiClient.get('/vocabulary/stats/overview');
    return response;
  }

  /// Đánh dấu đã học từ vựng
  Future<Map<String, dynamic>> markAsLearned(String vocabularyId) async {
    final response = await _apiClient.post('/vocabulary/learn/$vocabularyId', {});
    return response;
  }
}
