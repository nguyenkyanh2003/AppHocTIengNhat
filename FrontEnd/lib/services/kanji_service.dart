import '../core/api_client.dart';
import '../models/kanji.dart';

class KanjiService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách kanji với phân trang
  Future<Map<String, dynamic>> getKanjis({
    int page = 1,
    int limit = 20,
    String? level,
  }) async {
    try {
      List<String> params = [];
      params.add('page=$page');
      params.add('limit=$limit');
      if (level != null && level.isNotEmpty) {
        params.add('capDo=$level');  // Backend sử dụng capDo
      }
      
      String queryString = params.join('&');
      final dynamic response = await _apiClient.get('/kanji?$queryString');
      
      if (response is Map<String, dynamic>) {
        return {
          'kanjis': (response['data'] as List)
              .map((json) => Kanji.fromJson(json))
              .toList(),
          'total': response['totalItems'] ?? 0,
          'page': response['currentPage'] ?? page,
          'totalPages': response['totalPages'] ?? 1,
        };
      }
      
      return {
        'kanjis': [],
        'total': 0,
        'page': page,
        'totalPages': 1,
      };
    } catch (e) {
      throw Exception('Không thể tải danh sách Kanji: $e');
    }
  }

  // Tìm kiếm kanji
  Future<List<Kanji>> searchKanjis(String query) async {
    try {
      final dynamic response = await _apiClient.get('/kanji/search?keyword=$query');
      // Backend trả về array trực tiếp, không có 'data' wrapper
      if (response is List) {
        return response.map((json) => Kanji.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tìm kiếm Kanji: $e');
    }
  }

  // Lấy kanji theo level
  Future<List<Kanji>> getKanjisByLevel(String level) async {
    try {
      final dynamic response = await _apiClient.get('/kanji/level/$level');
      if (response is Map<String, dynamic> && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => Kanji.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải Kanji theo cấp độ: $e');
    }
  }

  // Lấy chi tiết kanji
  Future<Kanji> getKanjiById(String id) async {
    try {
      final dynamic response = await _apiClient.get('/kanji/$id');
      if (response is Map<String, dynamic> && response['data'] != null) {
        return Kanji.fromJson(response['data']);
      }
      throw Exception('Dữ liệu không hợp lệ');
    } catch (e) {
      throw Exception('Không thể tải chi tiết Kanji: $e');
    }
  }

  // Lấy kanji theo bài học
  Future<List<Kanji>> getKanjisByLesson(String lessonId) async {
    try {
      final dynamic response = await _apiClient.get('/kanji/lesson/$lessonId');
      if (response is Map<String, dynamic> && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => Kanji.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải Kanji theo bài học: $e');
    }
  }

  // Lấy kanji ngẫu nhiên để luyện tập
  Future<List<Kanji>> getRandomKanjis({int count = 10, String? level}) async {
    try {
      List<String> params = [];
      params.add('count=$count');
      if (level != null && level.isNotEmpty) {
        params.add('level=$level');
      }
      
      String queryString = params.join('&');
      final dynamic response = await _apiClient.get('/kanji/random?$queryString');
      if (response is Map<String, dynamic> && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => Kanji.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải Kanji ngẫu nhiên: $e');
    }
  }

  // Đánh dấu đã học kanji
  Future<Map<String, dynamic>> markAsLearned(String kanjiId) async {
    try {
      final response = await _apiClient.post('/kanji/learn/$kanjiId', {});
      return response;
    } catch (e) {
      throw Exception('Không thể đánh dấu đã học: $e');
    }
  }
}
