import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/lesson_progress.dart';

/// Tiến độ của người đang đăng nhập trên từng bài. Lỗi ném ra cho người gọi
/// quyết định cách báo — không lặng lẽ thành `null`.
class LessonProgressService {
  LessonProgressService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// `null` khi chưa bắt đầu bài.
  Future<LessonProgress?> getProgress(String lessonId) async {
    final data = dataOf(await _client.get('/lesson-progress/lesson/$lessonId'));
    return data is Map ? LessonProgress.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  /// Mở bài: tạo bản ghi tiến độ nếu chưa có (0 XP).
  Future<LessonProgress> startLesson(String lessonId) async =>
      _progressOf(await _client.post('/lesson-progress/lesson/$lessonId/start', const {}));

  /// Đánh dấu (hoặc bỏ đánh dấu) một từ, ngữ pháp, chữ Hán đã học.
  Future<LessonProgress> updateProgress({
    required String lessonId,
    required String itemType,
    required String itemId,
    required bool completed,
  }) async =>
      _progressOf(await _client.post('/lesson-progress/lesson/$lessonId/update', {
        'item_type': itemType,
        'item_id': itemId,
        'completed': completed,
      }));

  Future<LessonProgress> completeLesson(String lessonId) async =>
      _progressOf(await _client.post('/lesson-progress/lesson/$lessonId/complete', const {}));

  Future<void> resetProgress(String lessonId) => _client.post('/lesson-progress/lesson/$lessonId/reset', const {});

  static LessonProgress _progressOf(Object? response) => objectOf(response, LessonProgress.fromJson);
}
