import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/notebook.dart';

/// Sổ tay của người đang đăng nhập; server chỉ trả và chỉ sửa ghi chú của chính họ.
class NotebookService {
  NotebookService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  /// Mới tạo trước; [search] khớp nguyên văn trong tiêu đề hoặc nội dung.
  Future<Paged<Notebook>> list({int page = 1, int limit = pageSize, NoteType? type, String? search}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (type != null) 'type': type.name,
      if (search != null) 'search': search,
    }).query;
    return Paged.fromJson(await _client.get('/notebook?$query'), Notebook.fromJson);
  }

  Future<Notebook> detail(String id) async => objectOf(await _client.get('/notebook/$id'), Notebook.fromJson);

  Future<Notebook> create(NotebookDraft draft) async =>
      objectOf(await _client.post('/notebook', draft.toJson()), Notebook.fromJson);

  Future<Notebook> update(String id, NotebookDraft draft) async =>
      objectOf(await _client.put('/notebook/$id', draft.toJson()), Notebook.fromJson);

  Future<void> delete(String id) => _client.delete('/notebook/$id');
}
