import '../../../core/network/api_client.dart';
import '../../streaks/models/user_streak.dart';
import '../../streaks/services/streak_service.dart';

/// Người dùng bấm huỷ giữa chừng; không có tệp nào được tạo.
class ExportCancelled implements Exception {
  const ExportCancelled();
}

/// Các nhóm dữ liệu xuất được, theo khoá màn xuất dữ liệu dùng.
abstract final class ExportType {
  static const fullStats = 'full_stats';
  static const lessonProgress = 'lesson_progress';
  static const notebook = 'notebook';
  static const achievements = 'achievements';
  static const streaks = 'streaks';
  static const allData = 'all_data';
}

/// Gom dữ liệu học tập để xuất ra tệp.
///
/// Lịch sử XP và lịch học được đọc **hết mọi trang** tới khi server báo hết
/// (`next_cursor = null`), lịch học đọc lùi từng khoảng 366 ngày tới ngày sớm
/// nhất. Một trang lỗi làm hỏng cả lần xuất — không bao giờ ra một tệp thiếu
/// dữ liệu mà vẫn báo thành công (spec streak §4.2).
class ExportService {
  ExportService({ApiClient? client, StreakService? streakService})
      : _client = client ?? ApiClient(),
        _streak = streakService ?? StreakService(client: client);

  final ApiClient _client;
  final StreakService _streak;

  /// Độ dài một khoảng đọc lịch — đúng trần server chấp nhận.
  static const dayWindow = 366;

  Future<Map<String, dynamic>> load(String type, {bool Function()? isCancelled}) async {
    void checkpoint() {
      if (isCancelled?.call() ?? false) throw const ExportCancelled();
    }

    Future<Map<String, dynamic>> streakSection() async {
      final summary = Map<String, dynamic>.from(await _client.get('/streak/my-streak') as Map);
      checkpoint();
      final history = await _allXpHistory(checkpoint);
      final days = await _allDays(summary['first_day'] as String?, checkpoint);
      return {
        'streak': summary,
        'xp_history': history.map((item) => item.toJson()).toList(),
        'streak_days': days.map((day) => day.toJson()).toList(),
      };
    }

    final data = switch (type) {
      ExportType.fullStats => {
          'statistics': await _client.get('/progress/dashboard/stats'),
          'breakdown': await _client.get('/progress/dashboard/breakdown'),
          'streak': await _client.get('/streak/my-streak'),
        },
      ExportType.lessonProgress => {'lesson_progress': await _client.get('/progress')},
      ExportType.notebook => {'notebook': await _client.get('/notebook?limit=100')},
      ExportType.achievements => {'achievements': await _client.get('/achievement/my-achievements')},
      ExportType.streaks => await streakSection(),
      ExportType.allData => {
          'lesson_progress': await _client.get('/progress'),
          'statistics': await _client.get('/progress/dashboard/stats'),
          'notebook': await _client.get('/notebook?limit=100'),
          'achievements': await _client.get('/achievement/my-achievements'),
          ...await streakSection(),
        },
      _ => throw ArgumentError('Loại dữ liệu không hợp lệ: $type'),
    };
    checkpoint();
    return data;
  }

  Future<List<XPHistory>> _allXpHistory(void Function() checkpoint) async {
    final items = <XPHistory>[];
    String? cursor;
    do {
      final page = await _streak.getXpHistoryPage(cursor: cursor);
      checkpoint();
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return items;
  }

  /// Đọc lùi từng khoảng 366 ngày, mỗi khoảng đọc hết các trang, tới khi
  /// khoảng đã chứa [firstDay]. Chưa có ngày nào thì không đọc gì.
  Future<List<StreakDay>> _allDays(String? firstDay, void Function() checkpoint) async {
    if (firstDay == null) return const [];
    final days = <StreakDay>[];
    String? from;
    String? to;

    while (true) {
      String? cursor;
      StreakDaysPage page;
      do {
        page = await _streak.getDays(from: from, to: to, cursor: cursor);
        checkpoint();
        days.addAll(page.days);
        cursor = page.nextCursor;
      } while (cursor != null);

      if (page.from.compareTo(firstDay) <= 0) return days;
      to = shiftDay(page.from, -1);
      from = shiftDay(to, -(dayWindow - 1));
    }
  }

  /// Cộng/trừ ngày trên khoá `YYYY-MM-DD`, tính theo UTC để không lệch múi giờ máy.
  static String shiftDay(String dayKey, int days) {
    final date = DateTime.parse('${dayKey}T00:00:00Z').add(Duration(days: days));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }
}
