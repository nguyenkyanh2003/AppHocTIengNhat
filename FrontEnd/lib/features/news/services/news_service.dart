import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/news.dart';

/// Tin tức đọc công khai. Bài và danh sách theo cấp độ được lưu để đọc ngoại
/// tuyến; kết quả tìm kiếm thì không — mỗi từ khoá một mục là tràn bộ đệm.
class NewsService {
  NewsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 10;

  Future<Paged<News>> list({int page = 1, int limit = pageSize, String? level, String? search}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (level != null && level.isNotEmpty) 'level': level,
      if (search != null && search.isNotEmpty) 'search': search,
    }).query;
    final response = await _client.get('/news?$query', cache: search == null || search.isEmpty);
    return Paged.fromJson(response, News.fromJson);
  }

  Future<News> detail(String id) async => objectOf(await _client.get('/news/$id', cache: true), News.fromJson);

  Future<List<News>> related(String id, {int limit = 5}) async =>
      listOf(await _client.get('/news/$id/related?limit=$limit', cache: true), News.fromJson);
}
