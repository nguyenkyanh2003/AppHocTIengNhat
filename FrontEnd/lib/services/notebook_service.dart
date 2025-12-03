import '../core/api_client.dart';
import '../models/notebook.dart';

class NotebookService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách ghi chú
  Future<Map<String, dynamic>> getNotes({
    int page = 1,
    int limit = 20,
    String? type,
    String? search,
  }) async {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');
    
    if (type != null && type.isNotEmpty) {
      params.add('type=$type');
    }
    
    if (search != null && search.isNotEmpty) {
      params.add('search=$search');
    }

    final queryString = params.join('&');
    final response = await _apiClient.get('/notebook?$queryString');

    return {
      'totalItems': response['totalItems'] ?? 0,
      'totalPages': response['totalPages'] ?? 0,
      'currentPage': response['currentPage'] ?? page,
      'data': (response['data'] as List?)
              ?.map((item) => Notebook.fromJson(item))
              .toList() ??
          [],
    };
  }

  /// Lấy chi tiết ghi chú
  Future<Notebook> getNoteById(String id) async {
    final response = await _apiClient.get('/notebook/$id');
    return Notebook.fromJson(response['data']);
  }

  /// Tạo ghi chú mới
  Future<Notebook> createNote(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/notebook', data);
    return Notebook.fromJson(response['data']);
  }

  /// Cập nhật ghi chú
  Future<Notebook> updateNote(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/notebook/$id', data);
    return Notebook.fromJson(response['data']);
  }

  /// Xóa ghi chú
  Future<void> deleteNote(String id) async {
    await _apiClient.delete('/notebook/$id');
  }

  /// Xóa nhiều ghi chú
  Future<int> deleteMultipleNotes(List<String> ids) async {
    final response = await _apiClient.delete('/notebook', {'ids': ids});
    return response['deletedCount'] ?? 0;
  }

  /// Lấy ghi chú theo item liên quan
  Future<List<Notebook>> getNotesByRelatedItem(
    String itemType,
    String itemId,
  ) async {
    final response = await _apiClient.get('/notebook/related/$itemType/$itemId');
    return (response['data'] as List?)
            ?.map((item) => Notebook.fromJson(item))
            .toList() ??
        [];
  }

  /// Lấy danh sách tags
  Future<List<String>> getAllTags() async {
    final response = await _apiClient.get('/notebook/tags/all');
    return (response['data'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        [];
  }

  /// Lấy thống kê ghi chú
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.get('/notebook/stats/me');
    return response;
  }
}
