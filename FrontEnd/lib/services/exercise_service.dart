import '../core/api_client.dart';
import '../models/exercise.dart';

class ExerciseService {
  final ApiClient _apiClient = ApiClient();

  // Lấy tất cả bài tập
  Future<List<Exercise>> getAllExercises() async {
    try {
      // Lấy tất cả bài tập từ các cấp độ
      final List<Exercise> allExercises = [];
      final levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
      
      for (final level in levels) {
        try {
          final dynamic response = await _apiClient.get('/exercise/level/$level');
          if (response is List) {
            allExercises.addAll(
              response.map((json) => Exercise.fromJson(json)).toList()
            );
          }
        } catch (e) {
          // Continue with other levels if one fails
          print('Error loading $level: $e');
        }
      }
      
      return allExercises;
    } catch (e) {
      throw Exception('Không thể tải danh sách bài tập: $e');
    }
  }

  // Lấy danh sách bài tập theo bài học
  Future<List<Exercise>> getExercisesByLesson(String lessonId) async {
    try {
      final dynamic response = await _apiClient.get('/exercise/lesson/$lessonId');
      if (response is List) {
        return response.map((json) => Exercise.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải danh sách bài tập: $e');
    }
  }

  // Lấy chi tiết bài tập
  Future<Exercise> getExerciseById(String id) async {
    try {
      final dynamic response = await _apiClient.get('/exercise/$id');
      if (response is Map<String, dynamic>) {
        return Exercise.fromJson(response);
      }
      throw Exception('Dữ liệu không hợp lệ');
    } catch (e) {
      throw Exception('Không thể tải chi tiết bài tập: $e');
    }
  }

  // Lấy danh sách bài tập theo level
  Future<List<Exercise>> getExercisesByLevel(String level) async {
    try {
      final dynamic response = await _apiClient.get('/exercise/level/$level');
      if (response is List) {
        return response.map((json) => Exercise.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải bài tập theo cấp độ: $e');
    }
  }

  // Lấy danh sách bài tập theo type
  Future<List<Exercise>> getExercisesByType(String type) async {
    try {
      final dynamic response = await _apiClient.get('/exercise/type/$type');
      if (response is List) {
        return response.map((json) => Exercise.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải bài tập theo loại: $e');
    }
  }

  // Nộp bài và nhận kết quả
  Future<ExerciseResult> submitExercise(
    String exerciseId,
    List<UserAnswer> answers,
    int timeSpent,
  ) async {
    try {
      final dynamic response = await _apiClient.post(
        '/exercise/submit/$exerciseId',
        {
          'answers': answers.map((a) => a.toJson()).toList(),
          'timeSpent': timeSpent,
        },
      );
      
      if (response is Map<String, dynamic>) {
        return ExerciseResult.fromJson(response);
      }
      throw Exception('Dữ liệu không hợp lệ');
    } catch (e) {
      throw Exception('Không thể nộp bài: $e');
    }
  }

  // Lấy lịch sử làm bài của user
  Future<List<ExerciseResult>> getUserExerciseHistory() async {
    try {
      final dynamic response = await _apiClient.get('/exercise/history');
      if (response is List) {
        return response.map((json) => ExerciseResult.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải lịch sử làm bài: $e');
    }
  }

  // Lấy kết quả chi tiết của 1 lần làm bài
  Future<ExerciseResult> getResultById(String resultId) async {
    try {
      final dynamic response = await _apiClient.get('/exercise/result/$resultId');
      if (response is Map<String, dynamic>) {
        return ExerciseResult.fromJson(response);
      }
      throw Exception('Dữ liệu không hợp lệ');
    } catch (e) {
      throw Exception('Không thể tải kết quả: $e');
    }
  }
}
