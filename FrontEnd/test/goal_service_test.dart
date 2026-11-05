import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/goals/models/learning_goal.dart';
import 'package:apphoctiengnnhat/features/goals/services/goal_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _goal = {
  'id': 'g1',
  'type': 'vocabulary',
  'title': 'Đạt 150 từ vựng',
  'target': 150,
  'current': 120,
  'is_completed': false,
  'completed_at': null,
  'deadline': '2026-12-31',
  'created_at': '2026-11-01T00:00:00.000Z',
};

void main() {
  test('đọc danh sách mục tiêu kèm số đã học hiện tại', () async {
    final snapshot = await http.runWithClient(
      () => GoalService().list(),
      () => MockClient((request) async {
        expect('${request.method} ${request.url.path}', 'GET /api/goal');
        return _json({'data': [_goal], 'total': 1, 'counts': {'lessons': 2, 'vocabulary': 120, 'kanji': 5}, 'available': {'lessons': 40, 'kanji': 33}});
      }),
    );

    final goal = snapshot.goals.single;
    expect((goal.id, goal.type, goal.title, goal.target, goal.current), ('g1', GoalType.vocabulary, 'Đạt 150 từ vựng', 150, 120));
    expect(goal.deadline, DateTime(2026, 12, 31));
    expect(goal.isCompleted, isFalse);
    expect(snapshot.counts.of(GoalType.kanji), 5);
    expect(snapshot.available.limitOf(GoalType.kanji), 33);
    expect(snapshot.available.limitOf(GoalType.lessons), 40);
    expect(snapshot.available.limitOf(GoalType.vocabulary), isNull, reason: 'từ vựng học được ở cả màn Từ vựng, không có trần theo bài');
  });

  test('tạo, sửa, xoá gửi đúng hợp đồng; bỏ trống tên thì không gửi', () async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      final service = GoalService();
      await service.create(const GoalDraft(type: GoalType.kanji, target: 10));
      await service.create(GoalDraft(type: GoalType.lessons, target: 5, title: 'Năm bài', deadline: DateTime(2026, 12, 1)));
      await service.update('g1', const GoalEdit(title: 'Mốc N5', deadline: null));
      await service.update('g1', GoalEdit(title: 'Mốc N5', target: 200, deadline: DateTime(2027, 1, 5)));
      await service.delete('g1');
    }, () => MockClient((request) async {
      requests.add(request);
      return request.method == 'DELETE' ? _json({'data': {'deleted': true}}) : _json({'data': _goal}, 201);
    }));

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /api/goal', 'POST /api/goal', 'PATCH /api/goal/g1', 'PATCH /api/goal/g1', 'DELETE /api/goal/g1',
    ]);
    expect(jsonDecode(requests[0].body), {'type': 'kanji', 'target': 10, 'deadline': null});
    expect(jsonDecode(requests[1].body), {'type': 'lessons', 'target': 5, 'title': 'Năm bài', 'deadline': '2026-12-01'});
    expect(jsonDecode(requests[2].body), {'title': 'Mốc N5', 'deadline': null});
    expect(jsonDecode(requests[3].body), {'title': 'Mốc N5', 'target': 200, 'deadline': '2027-01-05'});
  });

  test('lỗi nghiệp vụ của server được ném ra nguyên thông điệp', () async {
    await http.runWithClient(() async {
      await expectLater(
        GoalService().create(const GoalDraft(type: GoalType.vocabulary, target: 100)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('120 từ vựng'))),
      );
    }, () => MockClient((_) async => _json({
          'message': 'Bạn đã có 120 từ vựng; số cần đạt phải lớn hơn 120.',
          'code': 'GOAL_TARGET_REACHED',
          'details': {'current': 120},
        }, 400)));
  });

  test('quá hạn tính theo ngày trên máy; đã hoàn thành thì không còn quá hạn', () {
    final goal = LearningGoal.fromJson({..._goal, 'deadline': '2026-11-03'});
    expect(goal.isOverdue(DateTime(2026, 11, 3, 23, 59)), isFalse, reason: 'hạn là cả ngày hôm đó');
    expect(goal.isOverdue(DateTime(2026, 11, 4)), isTrue);
    expect(LearningGoal.fromJson({..._goal, 'deadline': '2026-11-03', 'is_completed': true}).isOverdue(DateTime(2026, 11, 4)), isFalse);
    expect(goal.progress, closeTo(0.8, 0.001));
    expect(goal.remaining, 30);
  });
}
