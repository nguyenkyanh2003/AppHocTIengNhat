import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

class SearchResult {
  final String id;
  final String type; // 'vocabulary', 'kanji', 'lesson', 'grammar', 'news'
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? level; // JLPT level if applicable

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.level,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? json['word'] ?? json['kanji'] ?? '',
      subtitle: json['subtitle'] ?? json['meaning'] ?? json['example'],
      description: json['description'] ?? json['definition'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      level: json['level'],
    );
  }
}

class SearchService {
  final ApiClient _apiClient = ApiClient();

  /// Tìm kiếm global
  Future<List<SearchResult>?> globalSearch(String query) async {
    try {
      if (query.isEmpty) return [];

      final List<SearchResult> results = [];

      // Search in multiple endpoints in parallel
      final responses = await Future.wait([
        _searchVocabulary(query),
        _searchKanji(query),
        _searchLesson(query),
        _searchGrammar(query),
        _searchNews(query),
      ]);

      for (var response in responses) {
        if (response != null) {
          results.addAll(response);
        }
      }

      // Sort by relevance
      results.sort((a, b) => a.title.compareTo(b.title));
      return results;
    } catch (e) {
      debugPrint('Error global search: $e');
      return null;
    }
  }

  /// Tìm kiếm từ vựng
  Future<List<SearchResult>?> _searchVocabulary(String query) async {
    try {
      final response =
          await _apiClient.get('/vocabulary?search=$query&limit=5');

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) {
            item['type'] = 'vocabulary';
            return SearchResult.fromJson(item);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching vocabulary: $e');
      return null;
    }
  }

  /// Tìm kiếm Kanji
  Future<List<SearchResult>?> _searchKanji(String query) async {
    try {
      final response = await _apiClient.get('/kanji?search=$query&limit=5');

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) {
            item['type'] = 'kanji';
            return SearchResult.fromJson(item);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching kanji: $e');
      return null;
    }
  }

  /// Tìm kiếm bài học
  Future<List<SearchResult>?> _searchLesson(String query) async {
    try {
      final response = await _apiClient.get('/lesson?search=$query&limit=5');

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) {
            item['type'] = 'lesson';
            return SearchResult.fromJson(item);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching lessons: $e');
      return null;
    }
  }

  /// Tìm kiếm ngữ pháp
  Future<List<SearchResult>?> _searchGrammar(String query) async {
    try {
      final response = await _apiClient.get('/grammar?search=$query&limit=5');

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) {
            item['type'] = 'grammar';
            return SearchResult.fromJson(item);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching grammar: $e');
      return null;
    }
  }

  /// Tìm kiếm tin tức
  Future<List<SearchResult>?> _searchNews(String query) async {
    try {
      final response = await _apiClient.get('/news?search=$query&limit=5');

      if (response != null && response is Map) {
        final data = response['data'] as List?;
        if (data != null) {
          return data.map((item) {
            item['type'] = 'news';
            return SearchResult.fromJson(item);
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching news: $e');
      return null;
    }
  }
}
