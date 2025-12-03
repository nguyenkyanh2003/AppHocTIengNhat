import '../core/api_client.dart';
import '../models/srs_progress.dart';

class SRSService {
  final ApiClient _apiClient = ApiClient();

  /// Get SRS progress for a specific item
  Future<SRSProgress?> getProgress(String itemId, String itemType) async {
    try {
      final response = await _apiClient.get(
        '/srs/progress/$itemId?item_type=$itemType',
      );
      return SRSProgress.fromJson(response);
    } catch (e) {
      print('Error getting SRS progress: $e');
      return null;
    }
  }

  /// Get all items due for review
  Future<List<SRSProgress>> getDueReviews({String? itemType}) async {
    try {
      final queryString = itemType != null ? '?item_type=$itemType' : '';
      final response = await _apiClient.get('/srs/due$queryString');

      if (response is List) {
        return response.map((json) => SRSProgress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting due reviews: $e');
      return [];
    }
  }

  /// Update SRS progress after review
  /// rating: 1 (Again), 2 (Hard), 3 (Good), 4 (Easy)
  Future<SRSProgress?> updateProgress({
    required String itemId,
    required String itemType,
    required int rating,
  }) async {
    try {
      final response = await _apiClient.post(
        '/srs/review',
        {
          'item_id': itemId,
          'item_type': itemType,
          'rating': rating,
        },
      );
      return SRSProgress.fromJson(response);
    } catch (e) {
      print('Error updating SRS progress: $e');
      return null;
    }
  }

  /// Get statistics for user's SRS progress
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _apiClient.get('/srs/statistics');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error getting SRS statistics: $e');
      return {
        'total': 0,
        'due_today': 0,
        'learned': 0,
        'mastered': 0,
      };
    }
  }

  /// Reset progress for an item
  Future<bool> resetProgress(String itemId, String itemType) async {
    try {
      await _apiClient.delete('/srs/progress/$itemId');
      return true;
    } catch (e) {
      print('Error resetting SRS progress: $e');
      return false;
    }
  }

  /// Get learning statistics by time period
  Future<Map<String, dynamic>> getLearningStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String();
      final end = endDate.toIso8601String();
      final response = await _apiClient.get(
        '/srs/stats?start_date=$start&end_date=$end',
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error getting learning stats: $e');
      return {};
    }
  }

  /// Get upcoming reviews count
  Future<int> getUpcomingReviewsCount() async {
    try {
      final response = await _apiClient.get('/srs/upcoming-count');
      return response['count'] ?? 0;
    } catch (e) {
      print('Error getting upcoming reviews count: $e');
      return 0;
    }
  }
}