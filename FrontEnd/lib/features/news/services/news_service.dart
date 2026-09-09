import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/news.dart';

class NewsService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tin tức có phân trang
  Future<Map<String, dynamic>> getNewsList({
    int page = 1,
    int limit = 10,
    String? level,
    String? search,
  }) async {
    try {
      String endpoint = '/news?page=$page&limit=$limit';

      if (level != null && level.isNotEmpty) {
        endpoint += '&level=$level';
      }
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }

      final response = await _apiClient.get(endpoint, cache: true);

      return {
        'total': response['totalItems'] ?? 0,
        'pages': response['totalPages'] ?? 1,
        'current_page': response['currentPage'] ?? 1,
        'data': (response['data'] as List<dynamic>?)
                ?.map((json) => News.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [],
      };
    } catch (e) {
      debugPrint('Error fetching news list: $e');
      rethrow;
    }
  }

  // Lấy chi tiết tin tức
  Future<News> getNewsDetail(String newsId) async {
    try {
      final response = await _apiClient.get('/news/$newsId', cache: true);

      if (response['data'] != null) {
        return News.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw Exception('News data not found');
    } catch (e) {
      debugPrint('Error fetching news detail: $e');
      rethrow;
    }
  }

  // Lấy tin tức liên quan
  Future<List<News>> getRelatedNews(String newsId, {int limit = 5}) async {
    try {
      final response = await _apiClient
          .get('/news/$newsId/related?limit=$limit', cache: true);

      return (response['data'] as List<dynamic>?)
              ?.map((json) => News.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      debugPrint('Error fetching related news: $e');
      return [];
    }
  }

  // Lấy danh sách level
  Future<List<String>> getLevels() async {
    try {
      return ['N5', 'N4', 'N3', 'N2', 'N1'];
    } catch (e) {
      debugPrint('Error fetching levels: $e');
      return [];
    }
  }
}
