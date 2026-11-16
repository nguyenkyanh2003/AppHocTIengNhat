import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/jlpt_models.dart';
import '../models/jlpt_practice_question.dart';

class JLPTService {
  JLPTService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 10;

  /// Đề đã xuất bản, mới nhất trước, kèm kết quả gần nhất của người đang xem.
  Future<Paged<JLPTExamBrief>> list({String? level, int? year, int? month, int page = 1, int limit = pageSize}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (level != null) 'level': level,
      if (year != null) 'year': '$year',
      if (month != null) 'month': '$month',
    }).query;
    return Paged.fromJson(await _client.get('/jlpt?$query'), JLPTExamBrief.fromJson);
  }

  /// Đề để thi: câu hỏi không kèm đáp án.
  Future<JLPTExamDetail> detail(String id) async => objectOf(await _client.get('/jlpt/$id'), JLPTExamDetail.fromJson);

  /// Nộp một lượt thi; [answers] là khoá câu (`moji-0`, `dokkai-1-2`...) → lựa
  /// chọn 0–3. Gửi lại đúng [attemptId] cũ thì server trả kết quả đã chấm.
  Future<JLPTSubmitResult> submit(
    String id, {
    required String attemptId,
    required Map<String, int> answers,
    required int timeSpent,
  }) async {
    final response = await _client.post('/jlpt/$id/submit', {
      'attempt_id': attemptId,
      'answers': [
        for (final MapEntry(key: key, value: choice) in answers.entries) {'question_key': key, 'selected': choice},
      ],
      'time_spent': timeSpent,
    });
    return objectOf(response, JLPTSubmitResult.fromJson);
  }

  /// Đáp án và lời giải của mọi câu, chỉ mở sau khi đã nộp đề.
  Future<List<JLPTQuestion>> solutions(String id) async =>
      objectOf(await _client.get('/jlpt/$id/solutions'), JLPTExamDetail.fromJson).allQuestions;

  /// Câu luyện nhanh theo kỹ năng, rút ngẫu nhiên từ các đề đã xuất bản.
  Future<List<JlptPracticeQuestion>> practice({required String type, String? level, int limit = 10}) async {
    final query = Uri(queryParameters: {'type': type, if (level != null) 'level': level, 'limit': '$limit'}).query;
    return listOf(await _client.get('/jlpt/practice?$query'), JlptPracticeQuestion.fromJson);
  }
}
