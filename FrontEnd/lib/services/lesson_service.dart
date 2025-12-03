import '../core/api_client.dart';
import '../models/lesson.dart';

class LessonService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách bài học với phân trang và filter
  Future<Map<String, dynamic>> getLessons({
    int page = 1,
    int limit = 10,
    String? level,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (level != null && level.isNotEmpty) {
        queryParams['capDo'] = level;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      String endpoint = '/lesson?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      final data = await _apiClient.get(endpoint);
      
      return {
        'totalItems': data['totalItems'] ?? 0,
        'totalPages': data['totalPages'] ?? 0,
        'currentPage': data['currentPage'] ?? 1,
        'lessons': (data['data'] as List)
            .map((json) => Lesson.fromJson(json))
            .toList(),
      };
    } catch (e) {
      throw Exception('Lỗi khi tải bài học: $e');
    }
  }

  // Lấy chi tiết bài học theo ID
  Future<LessonDetail> getLessonDetail(String id) async {
    try {
      final data = await _apiClient.get('/lesson/$id');
      return LessonDetail.fromJson(data);
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết bài học: $e');
    }
  }

  // Lấy bài học theo level
  Future<List<Lesson>> getLessonsByLevel(String level) async {
    try {
      final data = await _apiClient.get('/lesson/level/$level');
      return (data['data'] as List)
          .map((json) => Lesson.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải bài học: $e');
    }
  }

  // Lấy thống kê bài học
  Future<Map<String, dynamic>> getLessonStats() async {
    try {
      return await _apiClient.get('/lesson/stats/overview');
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê: $e');
    }
  }

  // Tạo bài học mới (Admin only)
  Future<Lesson> createLesson({
    required String title,
    required String level,
    required String description,
    String? contentHtml,
  }) async {
    try {
      final data = await _apiClient.post('/lesson', {
        'TenBaiHoc': title,
        'CapDo': level,
        'LoaiBaiHoc': description,
        'NoiDung': contentHtml ?? '',
      });
      return Lesson.fromJson(data['data']);
    } catch (e) {
      throw Exception('Lỗi khi tạo bài học: $e');
    }
  }

  // Cập nhật bài học (Admin only)
  Future<Lesson> updateLesson({
    required String id,
    String? title,
    String? level,
    String? description,
    String? contentHtml,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['TenBaiHoc'] = title;
      if (level != null) body['CapDo'] = level;
      if (description != null) body['LoaiBaiHoc'] = description;
      if (contentHtml != null) body['NoiDung'] = contentHtml;

      final data = await _apiClient.put('/lesson/$id', body);
      return Lesson.fromJson(data['data']);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật bài học: $e');
    }
  }

  // Xóa bài học (Admin only)
  Future<void> deleteLesson(String id) async {
    try {
      await _apiClient.delete('/lesson/$id');
    } catch (e) {
      throw Exception('Lỗi khi xóa bài học: $e');
    }
  }

  // Sao chép bài học (Admin only)
  Future<Lesson> duplicateLesson(String id) async {
    try {
      final data = await _apiClient.post('/lesson/$id/duplicate', {});
      return Lesson.fromJson(data['data']);
    } catch (e) {
      throw Exception('Lỗi khi sao chép bài học: $e');
    }
  }
}
