import '../../../core/network/api_client.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/services/lesson_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../../vocabulary/services/vocabulary_service.dart';
import '../models/next_lesson.dart';

/// Dữ liệu riêng của Trang chủ, ghép từ các API sẵn có (không thêm endpoint).
class HomeService {
  HomeService({
    ApiClient? apiClient,
    LessonService? lessonService,
    VocabularyService? vocabularyService,
    NotificationService? notificationService,
  })  : _api = apiClient ?? ApiClient(),
        _lessons = lessonService ?? LessonService(),
        _vocabulary = vocabularyService ?? VocabularyService(),
        _notifications = notificationService ?? NotificationService();

  final ApiClient _api;
  final LessonService _lessons;
  final VocabularyService _vocabulary;
  final NotificationService _notifications;

  /// Bài học tiếp theo. Trình độ lấy theo bài vừa học gần nhất; chưa học bài
  /// nào thì theo [fallbackLevel] (trình độ trong hồ sơ).
  Future<NextLesson?> loadNextLesson({required String fallbackLevel}) async {
    final raw = await _api.get('/lesson-progress/lessons');
    final entries = (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final progress = entries
        .map(LessonProgressSummary.tryParse)
        .whereType<LessonProgressSummary>()
        .toList();

    // API trả theo lần học gần nhất trước; lấy trình độ của bài đó.
    final recentLevel = entries
        .map((e) => e['lesson'])
        .whereType<Map>()
        .map((lesson) => lesson['level']?.toString())
        .firstWhere((level) => level != null && level.isNotEmpty,
            orElse: () => null);
    final level = recentLevel ?? fallbackLevel;

    final page = await _lessons.getLessons(level: level, limit: 50);
    final lessons = (page['lessons'] as List<Lesson>?) ?? const [];
    return pickNextLesson(level: level, lessons: lessons, progress: progress);
  }

  /// "Từ mới hôm nay": một từ thật của trình độ [level], đổi theo ngày và giữ
  /// nguyên trong ngày (mọi lần mở Trang chủ trong ngày cùng một từ).
  Future<Vocabulary?> loadWordOfDay(
      {required String level, required DateTime today}) async {
    final first =
        await _vocabulary.getVocabularies(level: level, page: 1, limit: 1);
    if (first.total == 0 || first.items.isEmpty) return null;
    final index = dayNumber(today) % first.total;
    if (index == 0) return first.items.first;
    final page = await _vocabulary.getVocabularies(
        level: level, page: index + 1, limit: 1);
    return page.items.isEmpty ? first.items.first : page.items.first;
  }

  Future<int> unreadNotifications() => _notifications.getUnreadCount();
}

/// Số thứ tự ngày theo lịch (không theo giờ), để từ của ngày đổi đúng lúc nửa
/// đêm và không nhảy khi đổi múi giờ mùa hè.
int dayNumber(DateTime day) => DateTime.utc(day.year, day.month, day.day)
    .difference(DateTime.utc(2024))
    .inDays;
