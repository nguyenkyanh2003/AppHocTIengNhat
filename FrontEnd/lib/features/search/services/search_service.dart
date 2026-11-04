import '../../../core/network/api_client.dart';
import '../models/search_result.dart';

/// Tìm kiếm chung trên từ vựng, Kanji, bài học, ngữ pháp và tin tức qua một
/// endpoint duy nhất; server lọc, xếp độ liên quan và giới hạn từng nhóm.
class SearchService {
  final ApiClient _apiClient = ApiClient();

  static const int limitPerType = 5;

  /// Không đặt `cache`: mỗi từ khoá là một endpoint riêng, lưu ngoại tuyến
  /// từng lần gõ chỉ làm phình bộ nhớ đệm. Lỗi được ném ra để màn hình báo
  /// lỗi, không biến thành "không có kết quả".
  Future<List<SearchResult>> search(String query) async {
    final params = Uri(queryParameters: {'q': query, 'limit_per_type': '$limitPerType'});
    final response = await _apiClient.get('/search?${params.query}');
    return SearchResult.listFromJson(response['data']);
  }
}
