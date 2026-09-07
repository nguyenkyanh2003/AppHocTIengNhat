import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/grammar.dart';

class GrammarService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách ngữ pháp với phân trang và lọc
  Future<Map<String, dynamic>?> getGrammars({
    int page = 1,
    int limit = 10,
    String? level,
    String? search,
    String? lessonId,
    String? sortBy,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        if (level != null) 'level': level,
        if (search != null) 'search': search,
        if (lessonId != null) 'lessonID': lessonId,
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response = await _apiClient.get(
        '/grammar?${_buildQueryString(params)}',
      );
      return response;
    } catch (e) {
      debugPrint('Error fetching grammars: $e');
      return null;
    }
  }

  /// Lấy chi tiết một ngữ pháp
  Future<Grammar?> getGrammarDetail(String grammarId) async {
    try {
      final response = await _apiClient.get('/grammar/$grammarId');
      return Grammar.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching grammar detail: $e');
      return null;
    }
  }

  /// Lấy ngữ pháp theo cấp độ JLPT
  Future<Map<String, dynamic>?> getGrammarsByLevel(String level) async {
    try {
      final response = await _apiClient.get(
        '/grammar?level=$level',
      );
      return response;
    } catch (e) {
      debugPrint('Error fetching grammars by level: $e');
      return null;
    }
  }

  /// Lấy ngữ pháp theo bài học
  Future<List<Grammar>?> getGrammarsByLesson(String lessonId) async {
    try {
      final response = await _apiClient.get(
        '/grammar?lessonID=$lessonId',
      );

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) => Grammar.fromJson(item)).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching grammars by lesson: $e');
      return null;
    }
  }

  /// Tìm kiếm ngữ pháp
  Future<Map<String, dynamic>?> searchGrammars(String query) async {
    try {
      final response = await _apiClient.get(
        '/grammar?search=$query',
      );
      return response;
    } catch (e) {
      debugPrint('Error searching grammars: $e');
      return null;
    }
  }

  /// Tăng view count cho ngữ pháp
  Future<bool> incrementGrammarView(String grammarId) async {
    try {
      await _apiClient.post('/grammar/$grammarId/view', {});
      return true;
    } catch (e) {
      debugPrint('Error incrementing view: $e');
      return false;
    }
  }

  /// Yêu thích ngữ pháp
  Future<bool> favoriteGrammar(String grammarId) async {
    try {
      await _apiClient.post('/grammar/$grammarId/favorite', {});
      return true;
    } catch (e) {
      debugPrint('Error favoriting grammar: $e');
      return false;
    }
  }

  /// Bỏ yêu thích ngữ pháp
  Future<bool> unfavoriteGrammar(String grammarId) async {
    try {
      await _apiClient.delete('/grammar/$grammarId/favorite');
      return true;
    } catch (e) {
      debugPrint('Error unfavoriting grammar: $e');
      return false;
    }
  }

  String _buildQueryString(Map<String, dynamic> params) {
    final queryParts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        queryParts.add('$key=$value');
      }
    });
    return queryParts.join('&');
  }
}
