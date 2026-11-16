import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/exercise.dart';

class ExerciseService {
  ExerciseService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  /// Mọi bài tập, gộp năm cấp độ.
  ///
  /// Một cấp lỗi thì báo lỗi cả danh sách: hiện thiếu một cấp sẽ khiến lọc cấp
  /// đó ra "không có bài tập", là kết luận sai.
  Future<List<Exercise>> listAll() async {
    final responses = await Future.wait([
      for (final level in _levels) _client.get('/exercise/level/$level', cache: true),
    ]);
    return [for (final response in responses) ...listOf(response, Exercise.fromJson)];
  }

  Future<List<Exercise>> listByLesson(String lessonId) async =>
      listOf(await _client.get('/exercise/lesson/$lessonId', cache: true), Exercise.fromJson);

  /// Đề để làm bài: câu trả lời không kèm cờ đúng/sai, không có lời giải.
  Future<Exercise> detail(String id) async =>
      objectOf(await _client.get('/exercise/$id', cache: true), Exercise.fromJson);

  /// Nộp bài; [answers] là mã câu hỏi → mã đáp án đã chọn. Gửi lại đúng
  /// [attemptId] cũ thì server trả kết quả đã chấm thay vì chấm và cộng XP lần hai.
  Future<ExerciseResult> submit(
    String exerciseId, {
    required Map<String, String> answers,
    required int timeSpent,
    required String attemptId,
  }) async {
    final response = await _client.post('/exercise/submit/$exerciseId', {
      'attempt_id': attemptId,
      'answers': [
        for (final MapEntry(key: question, value: answer) in answers.entries) {'question_id': question, 'answer_id': answer},
      ],
      'timeSpent': timeSpent,
    });
    return objectOf(response, ExerciseResult.fromJson);
  }

  /// Kết quả các lần làm bài của người đang đăng nhập, mới nhất trước.
  Future<Paged<ExerciseResult>> history({int page = 1, int limit = pageSize}) async {
    final query = Uri(queryParameters: {'page': '$page', 'limit': '$limit'}).query;
    return Paged.fromJson(await _client.get('/exercise/history?$query'), ExerciseResult.fromJson);
  }

  /// Một kết quả kèm đề đầy đủ (đáp án đúng, lời giải) để xem lại.
  Future<ExerciseResult> result(String id) async =>
      objectOf(await _client.get('/exercise/result/$id'), ExerciseResult.fromJson);
}
