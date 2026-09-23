import '../../../core/network/api_client.dart';
import '../models/srs_card.dart';
import '../models/srs_progress.dart';

/// Sáu endpoint SRS (spec SRS §3.3). Định danh là id **từ vựng**, không phải
/// id tiến độ.
///
/// Không cache ngoại tuyến và không tự gửi lại: danh sách đến hạn và lịch ôn
/// là dữ liệu cá nhân thay đổi sau mỗi lượt, bản cũ sẽ gửi sai lịch kỳ vọng.
/// Lỗi giữ nguyên `statusCode`/`code`/`details` của [ApiException] để provider
/// phân biệt được 404, `SRS_NOT_DUE`, `SRS_PROGRESS_CHANGED`, `ITEM_UNAVAILABLE`.
class SrsService {
  SrsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const defaultLimit = 20;

  /// Query của `GET /srs/due`: loại trùng danh sách loại trừ, bỏ hẳn tham số
  /// khi rỗng.
  static Map<String, String> buildDueQuery({
    List<String> excludeItemIds = const [],
    int limit = defaultLimit,
  }) {
    final excluded = excludeItemIds.toSet();
    return {
      'item_type': SrsProgress.itemTypeVocabulary,
      'limit': '$limit',
      if (excluded.isNotEmpty) 'exclude_item_ids': excluded.join(','),
    };
  }

  /// Body của một lượt ôn: boolean tự đánh giá và mốc hạn ôn nguyên vẹn.
  static Map<String, dynamic> buildReviewBody({
    required String itemId,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) =>
      {
        'item_id': itemId,
        'item_type': SrsProgress.itemTypeVocabulary,
        'is_correct': isCorrect,
        'expected_next_review': expectedNextReview.toUtc().toIso8601String(),
      };

  Future<SrsBatch> fetchDue({
    List<String> excludeItemIds = const [],
    int limit = defaultLimit,
  }) async {
    final query = buildDueQuery(excludeItemIds: excludeItemIds, limit: limit);
    final response = await _client.get('/srs/due?${Uri(queryParameters: query).query}');
    return SrsBatch(
      cards: (response['data'] as List? ?? const [])
          .map((card) => SrsCard.fromJson(Map<String, dynamic>.from(card)))
          .toList(),
      limit: response['limit'] as int? ?? limit,
    );
  }

  /// Tổng từ vựng đến hạn — độc lập với đợt đang ôn và danh sách loại trừ.
  Future<int> fetchDueCount() async {
    final response = await _client.get('/srs/due/count');
    return (response['data'] as Map?)?['total'] as int? ?? 0;
  }

  Future<SrsStats> fetchStats() async {
    final response = await _client.get('/srs/stats');
    return SrsStats.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<SrsProgress> review({
    required String itemId,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) async {
    final response = await _client.post(
      '/srs/review',
      buildReviewBody(
        itemId: itemId,
        isCorrect: isCorrect,
        expectedNextReview: expectedNextReview,
      ),
    );
    return SrsProgress.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Đưa thẻ về hộp 1, ôn lại sau 24 giờ — được cả khi chưa đến hạn.
  Future<SrsProgress> reset({
    required String itemId,
    required DateTime expectedNextReview,
  }) async {
    final response = await _client.post('/srs/items/$itemId/reset', {
      'item_type': SrsProgress.itemTypeVocabulary,
      'expected_next_review': expectedNextReview.toUtc().toIso8601String(),
    });
    return SrsProgress.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Xoá tiến độ (bỏ dấu đã học). `false` nghĩa là không còn gì để xoá.
  Future<bool> remove({required String itemId}) async {
    final response = await _client.delete('/srs/items/$itemId');
    return (response['data'] as Map?)?['deleted'] as bool? ?? false;
  }
}
