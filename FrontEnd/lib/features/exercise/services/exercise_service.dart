import '../../../core/network/api_client.dart';
import '../models/exercise.dart';

class ExerciseService {
  final ApiClient _apiClient = ApiClient();

  // Lấy tất cả bài tập
  Future<List<Exercise>> getAllExercises() async {
    // Một cấp lỗi thì báo lỗi cả danh sách: hiện thiếu một cấp sẽ khiến lọc cấp đó
    // ra "không có bài tập", là kết luận sai. Server trả mảng rỗng cho cấp không có bài.
    final responses = await Future.wait([
      for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1'])
        _apiClient.get('/exercise/level/$level', cache: true),
    ]);
    return [
      for (final response in responses)
        if (response is List)
          ...response.map((json) => Exercise.fromJson(json)),
    ];
  }

  // Lấy danh sách bài tập theo bài học
  Future<List<Exercise>> getExercisesByLesson(String lessonId) async {
    final dynamic response =
        await _apiClient.get('/exercise/lesson/$lessonId', cache: true);
    if (response is List) {
      return response.map((json) => Exercise.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy chi tiết bài tập
  Future<Exercise> getExerciseById(String id) async {
    final dynamic response = await _apiClient.get('/exercise/$id', cache: true);
    if (response is Map<String, dynamic>) {
      return Exercise.fromJson(response);
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  // Lấy danh sách bài tập theo level
  Future<List<Exercise>> getExercisesByLevel(String level) async {
    final dynamic response =
        await _apiClient.get('/exercise/level/$level', cache: true);
    if (response is List) {
      return response.map((json) => Exercise.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy danh sách bài tập theo type
  Future<List<Exercise>> getExercisesByType(String type) async {
    final dynamic response =
        await _apiClient.get('/exercise/type/$type', cache: true);
    if (response is List) {
      return response.map((json) => Exercise.fromJson(json)).toList();
    }
    return [];
  }

  // Nộp bài và nhận kết quả
  /// [attemptId] định danh lượt làm; gửi lại đúng ID cũ thì server trả lại
  /// kết quả đã chấm thay vì chấm và cộng XP lần hai.
  Future<ExerciseResult> submitExercise(
    String exerciseId,
    List<UserAnswer> answers,
    int timeSpent, {
    required String attemptId,
  }) async {
    final dynamic response = await _apiClient.post(
      '/exercise/submit/$exerciseId',
      {
        'attempt_id': attemptId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'timeSpent': timeSpent,
      },
    );

    if (response is Map<String, dynamic>) {
      return ExerciseResult.fromJson(response);
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  // Lấy lịch sử làm bài của user
  Future<List<ExerciseResult>> getUserExerciseHistory() async {
    final dynamic response = await _apiClient.get('/exercise/history');
    if (response is List) {
      return response.map((json) => ExerciseResult.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy kết quả chi tiết của 1 lần làm bài
  Future<ExerciseResult> getResultById(String resultId) async {
    final dynamic response = await _apiClient.get('/exercise/result/$resultId');
    if (response is Map<String, dynamic>) {
      return ExerciseResult.fromJson(response);
    }
    throw Exception('Dữ liệu không hợp lệ');
  }
}
