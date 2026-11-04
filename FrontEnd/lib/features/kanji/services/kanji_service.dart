import '../../../core/network/api_client.dart';
import '../../srs/models/srs_progress.dart';
import '../models/kanji.dart';

class KanjiService {
  KanjiService({ApiClient? client}) : _apiClient = client ?? ApiClient();

  final ApiClient _apiClient;

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
        params.add('capDo=$level'); // Backend sử dụng capDo
      }

      String queryString = params.join('&');
      final dynamic response =
          await _apiClient.get('/kanji?$queryString', cache: true);

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
      final dynamic response =
          await _apiClient.get('/kanji/search?keyword=$query', cache: true);
      // Backend trả về array trực tiếp, không có 'data' wrapper
      if (response is List) {
        return response
            .map((json) => Kanji.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tìm kiếm Kanji: $e');
    }
  }

  // Lấy kanji theo level
  Future<List<Kanji>> getKanjisByLevel(String level) async {
    try {
      final dynamic response =
          await _apiClient.get('/kanji/level/$level', cache: true);
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

  /// Chi tiết một chữ kèm thẻ ôn của người đang xem.
  ///
  /// Không đặt `cache`: trạng thái "đã thêm vào ôn tập" đổi sau mỗi lần bấm,
  /// bản lưu ngoại tuyến sẽ hiện trạng thái cũ (giống chi tiết từ vựng). Lỗi
  /// giữ nguyên [ApiException] để provider báo đúng câu của server.
  Future<Kanji> getKanjiById(String id) async {
    final response = await _apiClient.get('/kanji/$id');
    return Kanji.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Thêm chữ vào lịch ôn: tạo thẻ hộp 1, hoặc trả thẻ đã có (bấm hai lần
  /// vẫn một thẻ). Không cộng XP — XP đến từ các lượt ôn.
  Future<SrsProgress> addToReview(String id) async {
    final response = await _apiClient.post('/kanji/$id/mark-learned', const {});
    return SrsProgress.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Gỡ chữ khỏi lịch ôn cùng toàn bộ tiến độ ôn của nó.
  Future<void> removeFromReview(String id) async {
    await _apiClient.delete('/kanji/$id/mark-learned');
  }

  // Lấy kanji theo bài học
  Future<List<Kanji>> getKanjisByLesson(String lessonId) async {
    try {
      final dynamic response =
          await _apiClient.get('/kanji/lesson/$lessonId', cache: true);
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
      final dynamic response =
          await _apiClient.get('/kanji/random?$queryString');
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
}
