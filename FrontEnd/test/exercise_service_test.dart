import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/exercise/services/exercise_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: const {'content-type': 'application/json; charset=utf-8'});

Map<String, Object?> _exercise(String id, String level) =>
    {'_id': id, 'title': 'Bài $id', 'type': 'Từ vựng', 'level': level, 'question_count': 3, 'time_limit': 10};

/// Kết quả đúng hình dạng server trả cho cả lần nộp lẫn lịch sử/xem lại.
const _result = {
  '_id': 'r1',
  'exercise_id': 'e1',
  'exercise': {
    '_id': 'e1',
    'title': 'Bài e1',
    'type': 'Từ vựng',
    'level': 'N5',
    'questions': [
      {
        '_id': 'q1',
        'content': '「駅」nghĩa là gì?',
        'explanation': '駅（えき）: nhà ga',
        'answers': [
          {'_id': 'a1', 'content': 'nhà ga', 'is_correct': true},
          {'_id': 'a2', 'content': 'vé', 'is_correct': false},
        ],
      },
    ],
  },
  'score': 100,
  'correct_answers': 1,
  'total_questions': 1,
  'time_spent': 42,
  'passed': true,
  'answers': [
    {'question_id': 'q1', 'answer_id': 'a1', 'is_correct': true, 'correct_answer_id': 'a1'},
  ],
  'createdAt': '2026-11-14T03:00:00.000Z',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mọi bài tập gộp năm cấp độ, mỗi cấp đọc `{ data, total }`', () async {
    final exercises = await http.runWithClient(
      () => ExerciseService().listAll(),
      () => MockClient((request) async {
        final level = request.url.pathSegments.last;
        return _json({'data': level == 'N5' ? [_exercise('e1', 'N5')] : [], 'total': level == 'N5' ? 1 : 0});
      }),
    );

    expect(exercises.single.questionCount, 3);
  });

  test('nộp bài gửi đúng lượt làm và bài làm, đọc kết quả trong `data`', () async {
    late Map<String, dynamic> sent;
    final result = await http.runWithClient(
      () => ExerciseService().submit('e1', answers: {'q1': 'a1'}, timeSpent: 42, attemptId: 'attempt-1'),
      () => MockClient((request) async {
        expect(request.url.path, '/api/exercise/submit/e1');
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({'data': _result}, 201);
      }),
    );

    expect(sent, {
      'attempt_id': 'attempt-1',
      'answers': [
        {'question_id': 'q1', 'answer_id': 'a1'},
      ],
      'timeSpent': 42,
    });
    expect((result.id, result.passed, result.correctAnswers), ('r1', true, 1));
  });

  test('lịch sử là trang kết quả; xem lại một kết quả có đề kèm đáp án và lời giải', () async {
    final service = ExerciseService();
    final (page, result) = await http.runWithClient(
      () async => (await service.history(page: 2), await service.result('r1')),
      () => MockClient((request) async => request.url.path.endsWith('/history')
          ? _json({'data': [_result], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2})
          : _json({'data': _result})),
    );

    expect((page.items.single.exercise?.title, page.hasMore), ('Bài e1', false));
    final question = result.exercise!.questions.single;
    expect((question.explanation, question.answers.first.isCorrect), ('駅（えき）: nhà ga', true));
    expect(result.answers.single.correctAnswerId, 'a1');
  });

  test('một cấp lỗi thì báo lỗi cả danh sách; response thiếu `data` là lỗi rõ ràng', () async {
    await expectLater(
      http.runWithClient(
        () => ExerciseService().listAll(),
        () => MockClient((request) async =>
            request.url.path.endsWith('/N3') ? _json({'message': 'Lỗi'}, 500) : _json({'data': [], 'total': 0})),
      ),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      http.runWithClient(() => ExerciseService().result('r1'), () => MockClient((_) async => _json(_result))),
      throwsA(isA<ServerException>()),
    );
  });
}
