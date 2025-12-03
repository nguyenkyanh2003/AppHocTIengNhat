import '../core/api_client.dart';
import '../models/lesson_progress.dart';

class LessonProgressService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy tiến độ học của user cho một lesson
  Future<LessonProgress?> getProgress(String lessonId) async {
    try {
      final data = await _apiClient.get('/lesson-progress/lesson/$lessonId');
      if (data == null || data.isEmpty) return null;
      return LessonProgress.fromJson(data);
    } catch (e) {
      print('Error getting lesson progress: $e');
      return null;
    }
  }

  /// Lấy tất cả tiến độ của user
  Future<List<LessonProgress>> getAllProgress() async {
    try {
      final data = await _apiClient.get('/lesson-progress/lessons');
      if (data is List) {
        return data.map((json) => LessonProgress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all lesson progress: $e');
      return [];
    }
  }

  /// Bắt đầu học một lesson (tạo progress record)
  Future<LessonProgress?> startLesson(String lessonId) async {
    try {
      final data = await _apiClient.post('/lesson-progress/lesson/$lessonId/start', {});
      return LessonProgress.fromJson(data);
    } catch (e) {
      print('Error starting lesson: $e');
      return null;
    }
  }

  /// Cập nhật tiến độ khi hoàn thành một item (vocabulary/grammar/kanji)
  Future<LessonProgress?> updateProgress({
    required String lessonId,
    required String itemType, // 'vocabulary', 'grammar', 'kanji'
    required String itemId,
    required bool completed,
  }) async {
    try {
      final data = await _apiClient.post(
        '/lesson-progress/lesson/$lessonId/update',
        {
          'item_type': itemType,
          'item_id': itemId,
          'completed': completed,
        },
      );
      return LessonProgress.fromJson(data);
    } catch (e) {
      print('Error updating lesson progress: $e');
      return null;
    }
  }

  /// Đánh dấu lesson hoàn thành
  Future<LessonProgress?> completeLesson(String lessonId) async {
    try {
      final data = await _apiClient.post('/lesson-progress/lesson/$lessonId/complete', {});
      return LessonProgress.fromJson(data);
    } catch (e) {
      print('Error completing lesson: $e');
      return null;
    }
  }

  /// Reset tiến độ của một lesson
  Future<bool> resetProgress(String lessonId) async {
    try {
      await _apiClient.post('/lesson-progress/lesson/$lessonId/reset', {});
      return true;
    } catch (e) {
      print('Error resetting lesson progress: $e');
      return false;
    }
  }

  /// Lấy thống kê tổng quan tiến độ học
  Future<Map<String, dynamic>> getOverallStats() async {
    try {
      final data = await _apiClient.get('/lesson-progress/stats');
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting progress stats: $e');
      return {
        'total_lessons': 0,
        'completed_lessons': 0,
        'in_progress_lessons': 0,
        'total_vocabularies_learned': 0,
        'total_grammars_learned': 0,
        'total_kanjis_learned': 0,
      };
    }
  }

  /// Lấy tiến độ theo level
  Future<Map<String, dynamic>> getProgressByLevel(String level) async {
    try {
      final data = await _apiClient.get('/lesson-progress/level/$level');
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting progress by level: $e');
      return {};
    }
  }
}
