import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/grammar.dart';

class GrammarService {
  GrammarService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  /// Một trang ngữ pháp đang hoạt động. Danh sách theo cấp độ được lưu để học
  /// ngoại tuyến; kết quả tìm kiếm thì không — mỗi từ khoá một mục là tràn bộ đệm.
  Future<Paged<Grammar>> list({
    int page = 1,
    int limit = pageSize,
    String? level,
    String? search,
    GrammarSort sort = GrammarSort.title,
  }) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (level != null && level.isNotEmpty) 'level': level,
      if (search != null && search.isNotEmpty) 'search': search,
      'sortBy': sort.name,
    }).query;
    final response = await _client.get('/grammar?$query', cache: search == null || search.isEmpty);
    return Paged.fromJson(response, Grammar.fromJson);
  }

  Future<Grammar> detail(String id) async =>
      objectOf(await _client.get('/grammar/$id', cache: true), Grammar.fromJson);
}
