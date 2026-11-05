import '../../../core/network/api_client.dart';
import '../models/srs_card.dart';
import '../models/srs_progress.dart';

/// Sáu endpoint SRS (spec SRS §3.3). Định danh là id **nội dung** (từ vựng
/// hoặc Kanji), không phải id tiến độ — nên mọi thao tác trên một thẻ gửi kèm
/// `item_type` của chính thẻ đó.
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
  /// khi rỗng. Không có [itemType] thì server trả mọi loại thẻ.
  static Map<String, String> buildDueQuery({
    List<String> excludeCardIds = const [],
    int limit = defaultLimit,
    String? itemType,
  }) {
    final excluded = excludeCardIds.toSet();
    return {
      if (itemType != null) 'item_type': itemType,
      'limit': '$limit',
      if (excluded.isNotEmpty) 'exclude_card_ids': excluded.join(','),
    };
  }

  /// Body của một lượt ôn: boolean tự đánh giá và mốc hạn ôn nguyên vẹn.
  static Map<String, dynamic> buildReviewBody({
    required String itemId,
    required String itemType,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) =>
      {
        'item_id': itemId,
        'item_type': itemType,
        'is_correct': isCorrect,
        'expected_next_review': expectedNextReview.toUtc().toIso8601String(),
      };

  Future<SrsBatch> fetchDue({
    List<String> excludeCardIds = const [],
    int limit = defaultLimit,
    String? itemType,
  }) async {
    final query = buildDueQuery(excludeCardIds: excludeCardIds, limit: limit, itemType: itemType);
    final response = await _client.get('/srs/due?${Uri(queryParameters: query).query}');
    return SrsBatch(
      cards: (response['data'] as List? ?? const [])
          .map((card) => SrsCard.fromJson(Map<String, dynamic>.from(card)))
          .toList(),
      limit: response['limit'] as int? ?? limit,
    );
  }

  /// Tổng thẻ đến hạn của mọi loại — độc lập với đợt đang ôn và danh sách loại trừ.
  Future<int> fetchDueCount() async {
    final response = await _client.get('/srs/due/count');
    return (response['data'] as Map?)?['total'] as int? ?? 0;
  }

  /// Phân bố hộp; không có [itemType] thì gộp mọi loại thẻ.
  Future<SrsStats> fetchStats({String? itemType}) async {
    final query = itemType == null ? '' : '?${Uri(queryParameters: {'item_type': itemType}).query}';
    final response = await _client.get('/srs/stats$query');
    return SrsStats.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<SrsProgress> review({
    required String itemId,
    required String itemType,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) async {
    final response = await _client.post(
      '/srs/review',
      buildReviewBody(
        itemId: itemId,
        itemType: itemType,
        isCorrect: isCorrect,
        expectedNextReview: expectedNextReview,
      ),
    );
    return SrsProgress.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Đưa thẻ về hộp 1, ôn lại sau 24 giờ — được cả khi chưa đến hạn.
  Future<SrsProgress> reset({
    required String itemId,
    required String itemType,
    required DateTime expectedNextReview,
  }) async {
    final response = await _client.post('/srs/items/$itemId/reset', {
      'item_type': itemType,
      'expected_next_review': expectedNextReview.toUtc().toIso8601String(),
    });
    return SrsProgress.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  /// Xoá tiến độ (gỡ thẻ khỏi lịch ôn). `false` nghĩa là không còn gì để xoá.
  Future<bool> remove({required String itemId, required String itemType}) async {
    final query = Uri(queryParameters: {'item_type': itemType}).query;
    final response = await _client.delete('/srs/items/$itemId?$query');
    return (response['data'] as Map?)?['deleted'] as bool? ?? false;
  }
}
