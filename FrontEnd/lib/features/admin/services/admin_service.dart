import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../lessons/models/lesson.dart';
import '../../notifications/models/notification.dart';
import '../models/admin_achievement.dart';
import '../models/admin_analytics.dart';
import '../models/admin_content_type.dart';
import '../models/admin_dashboard_summary.dart';
import '../models/admin_report.dart';
import '../models/admin_transaction.dart';
import '../models/admin_user.dart';

/// Mọi lời gọi API của trang quản trị. Lỗi ném lên cho provider báo.
///
/// Nội dung học (từ vựng, Kanji, ngữ pháp, bài học) đi dạng [JsonObject]: màn
/// quản trị sửa đúng các trường của document và xuất nguyên document ra CSV,
/// nên chính JSON là thứ được quản lý.
class AdminService {
  /// Nhận client qua constructor để test truyền transport giả.
  AdminService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Số mục mỗi trang của các danh sách quản trị; nội dung đọc tới trần server cho phép.
  static const pageSize = 20;
  static const contentPageSize = 50;

  // ---------------------------------------------------------------- Tổng quan

  Future<AdminDashboardSummary> dashboard() async {
    final [users, lessons, reports, analytics] = await Future.wait([
      _client.get('/users/admin/stats'),
      _client.get('/lesson/stats/overview'),
      _client.get('/report/admin/stats'),
      _client.get('/progress/admin/analytics?period=7d'),
    ]);
    return AdminDashboardSummary.fromStats({
      'users': dataOf(users),
      'lessons': dataOf(lessons),
      'reports': dataOf(reports),
      'analytics': dataOf(analytics),
    });
  }

  /// [period] là `7d`, `30d` hoặc `90d`.
  Future<AdminAnalytics> analytics({String period = '7d'}) async =>
      objectOf(await _client.get('/progress/admin/analytics${_query({'period': period})}'), AdminAnalytics.fromJson);

  // --------------------------------------------------------------- Người dùng

  Future<Paged<AdminUser>> users({int page = 1, String? search, AdminUserFilter filter = AdminUserFilter.all}) async {
    final query = _query({
      'page': page,
      'limit': pageSize,
      'search': search,
      'status': filter.status,
      'role': filter.role,
    });
    return Paged.fromJson(await _client.get('/users/admin/users$query'), AdminUser.fromJson);
  }

  Future<AdminUserStats> userStats() async =>
      objectOf(await _client.get('/users/admin/stats'), AdminUserStats.fromJson);

  /// Đổi vai trò (`user`/`admin`) hoặc trạng thái (`active`/`banned`).
  Future<AdminUser> updateUser(String id, {String? role, String? status}) async => objectOf(
        await _client.put('/users/admin/users/$id', {
          if (role != null) 'vaiTro': role,
          if (status != null) 'trangThai': status,
        }),
        AdminUser.fromJson,
      );

  Future<void> deleteUser(String id) => _client.delete('/users/admin/users/$id');

  /// Gửi thông báo cá nhân cho một người dùng.
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required NotificationType type,
  }) =>
      _client.post('/notifications', {
        'recipient_id': recipientId,
        'title': title,
        'message': message,
        'type': type.key,
      });

  /// Gửi cho mọi người học; trả số người đã nhận.
  Future<int> broadcastNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final data = dataOf(await _client.post('/notifications/broadcast/all', {
      'title': title,
      'message': message,
      'type': type.key,
    }));
    return data is Map ? (data['sent'] as num?)?.toInt() ?? 0 : 0;
  }

  // ----------------------------------------------------------------- Nội dung

  Future<Paged<JsonObject>> content(AdminContentType type, {int page = 1}) async => Paged.fromJson(
        await _client.get('${type.path}${_query({'page': page, 'limit': contentPageSize})}'),
        (json) => json,
      );

  Future<void> createContent(AdminContentType type, JsonObject document) => _client.post(type.path, document);

  Future<void> updateContent(AdminContentType type, String id, JsonObject document) =>
      _client.put('${type.path}/$id', document);

  Future<void> deleteContent(AdminContentType type, String id) => _client.delete('${type.path}/$id');

  /// Import từ vựng từ Excel.
  ///
  /// Backend bắt buộc `lesson` và `level` trong multipart và áp cho **mọi** dòng
  /// của tệp; thiếu một trong hai thì toàn bộ request bị từ chối với lỗi 400.
  Future<void> importVocabularyExcel(
    List<int> bytes,
    String fileName, {
    required String lesson,
    required String level,
  }) =>
      _client.postMultipart('/vocabulary/upload', {'lesson': lesson, 'level': level}, 'fileExcel', bytes, fileName);

  /// Import Kanji từ Excel.
  ///
  /// Khác với từ vựng: importer của Kanji đọc `BaiHocID` và `CapDo` từ **từng
  /// dòng** Excel, nên không gửi kèm metadata dùng chung cho cả tệp.
  Future<void> importKanjiExcel(List<int> bytes, String fileName) =>
      _client.postMultipart('/kanji/upload', const {}, 'fileExcel', bytes, fileName);

  /// Mọi bài học, để chọn bài gán cho tệp Excel từ vựng. Đọc hết các trang.
  Future<List<Lesson>> lessonOptions() async {
    final lessons = <Lesson>[];
    Paged<Lesson> page;
    var number = 1;
    do {
      page = Paged.fromJson(await _client.get('/lesson?page=${number++}&limit=100'), Lesson.fromJson);
      lessons.addAll(page.items);
    } while (page.hasMore);
    return lessons;
  }

  // ------------------------------------------------------------------ Báo cáo

  Future<Paged<AdminReport>> reports({int page = 1, String? status, String? type}) async {
    final query = _query({'page': page, 'limit': pageSize, 'status': status, 'type': type});
    return Paged.fromJson(await _client.get('/report/admin/all$query'), AdminReport.fromJson);
  }

  Future<AdminReportStats> reportStats() async =>
      objectOf(await _client.get('/report/admin/stats'), AdminReportStats.fromJson);

  /// Đổi trạng thái; [response] bỏ trống thì giữ phản hồi cũ.
  Future<void> updateReport(String id, {required String status, String? response}) =>
      _client.put('/report/admin/$id/status', {
        'status': status,
        if (response != null) 'admin_response': response,
      });

  Future<void> deleteReport(String id) => _client.delete('/report/admin/$id');

  // --------------------------------------------------------------- Thành tích

  Future<List<AdminAchievement>> achievements() async =>
      listOf(await _client.get('/achievement/admin/all'), AdminAchievement.fromJson);

  Future<void> createAchievement(AchievementDraft draft) => _client.post('/achievement/admin', draft.toJson());

  Future<void> updateAchievement(String id, AchievementDraft draft) =>
      _client.put('/achievement/admin/$id', draft.toJson());

  Future<void> deleteAchievement(String id) => _client.delete('/achievement/admin/$id');

  // ----------------------------------------------------------------- Giao dịch

  Future<Paged<AdminTransaction>> transactions({int page = 1, String? status}) async {
    final query = _query({'page': page, 'limit': pageSize, 'status': status});
    return Paged.fromJson(await _client.get('/transactions/admin/all$query'), AdminTransaction.fromJson);
  }

  Future<void> updateTransactionStatus(String id, String status) =>
      _client.put('/transactions/admin/$id/status', {'status': status});

  /// Query string bỏ qua giá trị `null` và chuỗi rỗng.
  static String _query(Map<String, Object?> values) {
    final parameters = {
      for (final MapEntry(:key, :value) in values.entries)
        if (value != null && '$value'.isNotEmpty) key: '$value',
    };
    return parameters.isEmpty ? '' : '?${Uri(queryParameters: parameters).query}';
  }
}
