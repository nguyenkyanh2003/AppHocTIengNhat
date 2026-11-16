import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/jlpt/services/jlpt_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _sections = {
  'moji_goi': [
    {'question_text': 'A', 'choices': ['1', '2'], 'correct_answer': 0},
  ],
  'bunpou': [],
  'dokkai': [
    {
      'group_content': 'Đoạn văn',
      'questions': [
        {'question_text': 'B', 'choices': ['1', '2'], 'correct_answer': 1},
        {'question_text': 'C', 'choices': ['1', '2'], 'correct_answer': 0},
      ],
    },
  ],
  'choukai': [],
};

void main() {
  test('danh sách đề là một trang, kèm kết quả gần nhất của người xem', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => JLPTService().list(level: 'N5'),
      () => MockClient((request) async {
        url = request.url;
        return _json({
          'data': [
            {
              '_id': 'e1',
              'title': 'N5 tháng 7',
              'level': 'N5',
              'time_limit': 105,
              'total_questions': 3,
              'createdAt': '2026-07-01T00:00:00.000Z',
              'last_result': {'score': 120, 'is_passed': true, 'completed_at': '2026-11-14T03:00:00.000Z'},
            },
          ],
          'page': 1,
          'limit': 10,
          'total': 1,
          'totalPages': 1,
        });
      }),
    );

    expect(url.queryParameters, {'page': '1', 'limit': '10', 'level': 'N5'});
    final exam = page.items.single;
    expect((exam.id, exam.totalQuestions, exam.lastResult?.score, exam.lastResult?.isPassed), ('e1', 3, 120, true));
  });

  test('nộp đề gửi một tên cho bài làm và thời gian, đọc điểm từng phần', () async {
    late Map<String, dynamic> sent;
    final result = await http.runWithClient(
      () => JLPTService().submit('e1', attemptId: 'attempt-1', answers: {'moji-0': 1}, timeSpent: 600),
      () => MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'data': {
            'passed': true,
            'total_score': 120,
            'section_scores': {'moji_goi': 40, 'bunpou': 30, 'dokkai': 30, 'choukai': 20},
            'duration': 600,
          },
        });
      }),
    );

    expect(sent, {
      'attempt_id': 'attempt-1',
      'answers': [
        {'question_key': 'moji-0', 'selected': 1},
      ],
      'time_spent': 600,
    });
    expect((result.passed, result.totalScore, result.vocabScore, result.listeningScore), (true, 120, 40, 20));
  });

  test('đáp án trải phẳng theo đúng thứ tự câu trong đề', () async {
    final solutions = await http.runWithClient(
      () => JLPTService().solutions('e1'),
      () => MockClient((_) async => _json({
            'data': {'_id': 'e1', 'title': 'N5', 'level': 'N5', 'sections': _sections},
          })),
    );

    expect(solutions.map((question) => (question.questionText, question.correctAnswer)), [('A', 0), ('B', 1), ('C', 0)]);
  });

  test('luyện nhanh đọc `{ data, total }`; response thiếu `data` là lỗi rõ ràng', () async {
    final questions = await http.runWithClient(
      () => JLPTService().practice(type: 'dokkai'),
      () => MockClient((_) async => _json({
            'data': [
              {'question_text': 'B', 'choices': ['1', '2'], 'correct_answer': 1, 'group_content': 'Đoạn văn'},
            ],
            'total': 1,
          })),
    );
    expect(questions.single.passage, 'Đoạn văn');

    await expectLater(
      http.runWithClient(() => JLPTService().detail('e1'), () => MockClient((_) async => _json({'_id': 'e1'}))),
      throwsA(isA<ServerException>()),
    );
  });
}
