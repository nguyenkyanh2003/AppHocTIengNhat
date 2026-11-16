import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/lesson.dart';

/// Bài học phía người học. Nội dung gần như không đổi nên lưu ngoại tuyến được.
class LessonService {
  LessonService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Đủ rộng để cả một trình độ (N5 hiện 12 bài) nằm trên một trang: lộ trình
  /// học bị cắt đôi giữa chừng thì khó theo, còn danh sách chỉ chở phần tóm tắt.
  static const pageSize = 20;

  Future<Paged<Lesson>> list({int page = 1, int limit = pageSize, String? level, String? situation, String? search}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (level != null) 'level': level,
      if (situation != null) 'situation': situation,
      if (search != null) 'search': search,
    }).query;
    return Paged.fromJson(await _client.get('/lesson?$query', cache: true), Lesson.fromJson);
  }

  /// Tình huống đang có bài học (ở [level] nếu có), để dựng bộ lọc: chỉ trả
  /// tình huống có nội dung nên không có chip bấm vào rỗng.
  Future<List<String>> situations({String? level}) async {
    final query = level == null ? '' : '?${Uri(queryParameters: {'level': level}).query}';
    final data = dataOf(await _client.get('/lesson/situations$query', cache: true));
    if (data is! List) throw ServerException('Máy chủ trả về dữ liệu không đúng định dạng.');
    return [for (final situation in data) '$situation'];
  }

  Future<LessonDetail> detail(String id) async =>
      objectOf(await _client.get('/lesson/$id', cache: true), LessonDetail.fromJson);
}
