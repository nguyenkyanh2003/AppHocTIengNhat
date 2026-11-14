import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../srs/models/srs_progress.dart';
import '../models/kanji.dart';

class KanjiService {
  KanjiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  /// Kho Kanji theo thứ tự giáo trình; lưu ngoại tuyến được vì không phụ thuộc người xem.
  Future<Paged<Kanji>> list({int page = 1, int limit = pageSize, String? level}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (level != null) 'level': level,
    }).query;
    return Paged.fromJson(await _client.get('/kanji?$query', cache: true), Kanji.fromJson);
  }

  /// Tối đa 50 chữ khớp [keyword] trên chữ, Hán Việt, âm On/Kun hoặc nghĩa.
  Future<List<Kanji>> search(String keyword, {String? level}) async {
    final query = Uri(queryParameters: {'keyword': keyword, if (level != null) 'level': level}).query;
    return listOf(await _client.get('/kanji/search?$query'), Kanji.fromJson);
  }

  /// Chi tiết một chữ kèm thẻ ôn của người đang xem.
  ///
  /// Không đặt `cache`: trạng thái "đã thêm vào ôn tập" đổi sau mỗi lần bấm,
  /// bản lưu ngoại tuyến sẽ hiện trạng thái cũ (giống chi tiết từ vựng).
  Future<Kanji> detail(String id) async => objectOf(await _client.get('/kanji/$id'), Kanji.fromJson);

  /// Thêm chữ vào lịch ôn: tạo thẻ hộp 1, hoặc trả thẻ đã có (bấm hai lần
  /// vẫn một thẻ). Không cộng XP — XP đến từ các lượt ôn.
  Future<SrsProgress> addToReview(String id) async =>
      objectOf(await _client.post('/kanji/$id/mark-learned', const {}), SrsProgress.fromJson);

  /// Gỡ chữ khỏi lịch ôn cùng toàn bộ tiến độ ôn của nó.
  Future<void> removeFromReview(String id) => _client.delete('/kanji/$id/mark-learned');
}
