import 'package:flutter_test/flutter_test.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/goals/models/learning_goal.dart';
import 'package:apphoctiengnnhat/features/goals/providers/goal_provider.dart';
import 'package:apphoctiengnnhat/features/goals/services/goal_service.dart';

LearningGoal _goal(String id, {GoalType type = GoalType.vocabulary, int target = 150, int current = 120}) => LearningGoal(
      id: id,
      type: type,
      title: 'Mục tiêu $id',
      target: target,
      current: current,
      isCompleted: current >= target,
      createdAt: DateTime.utc(2026, 11, 1),
    );

/// Service giả lưu trong bộ nhớ; mỗi lệnh có thể cài lỗi riêng.
class _FakeGoalService extends GoalService {
  _FakeGoalService(this.goals);

  final List<LearningGoal> goals;
  int lists = 0;
  Object? listError;
  Object? writeError;

  @override
  Future<GoalsSnapshot> list() async {
    lists++;
    if (listError != null) throw listError!;
    return GoalsSnapshot(goals: List.of(goals), counts: const GoalCounts(vocabulary: 120));
  }

  @override
  Future<LearningGoal> create(GoalDraft draft) async {
    if (writeError != null) throw writeError!;
    final goal = _goal('g${goals.length + 1}', type: draft.type, target: draft.target);
    goals.insert(0, goal);
    return goal;
  }

  @override
  Future<LearningGoal> update(String id, GoalEdit edit) async {
    if (writeError != null) throw writeError!;
    final index = goals.indexWhere((goal) => goal.id == id);
    final old = goals[index];
    return goals[index] = LearningGoal(id: id, type: old.type, title: edit.title, target: edit.target ?? old.target,
        current: old.current, isCompleted: old.isCompleted, createdAt: old.createdAt, deadline: edit.deadline);
  }

  @override
  Future<void> delete(String id) async {
    if (writeError != null) throw writeError!;
    goals.removeWhere((goal) => goal.id == id);
  }
}

List<String> _titles(GoalProvider provider) =>
    provider.state.valueOrNull?.goals.map((goal) => goal.title).toList() ?? const [];

void main() {
  test('tải danh sách; lỗi tải hiện thành lỗi chứ không thành danh sách rỗng', () async {
    final service = _FakeGoalService([_goal('g1')])..listError = ApiException('Mất kết nối máy chủ');
    final provider = GoalProvider(service: service);

    await provider.load();
    expect(provider.state.errorOrNull, 'Mất kết nối máy chủ');

    service.listError = null;
    await provider.load();
    expect(_titles(provider), ['Mục tiêu g1']);
    expect(provider.state.valueOrNull!.counts.of(GoalType.vocabulary), 120);
  });

  test('tạo mục tiêu: tải lại danh sách mà không chớp về trạng thái đang tải', () async {
    final service = _FakeGoalService([_goal('g1')]);
    final provider = GoalProvider(service: service);
    await provider.load();
    final loadingSeen = <bool>[];
    provider.addListener(() => loadingSeen.add(provider.state.isLoading));

    final error = await provider.create(const GoalDraft(type: GoalType.kanji, target: 10));

    expect(error, isNull);
    expect(_titles(provider), ['Mục tiêu g2', 'Mục tiêu g1']);
    expect(loadingSeen, isNot(contains(true)));
  });

  test('server từ chối thì trả thông điệp cho form, danh sách giữ nguyên', () async {
    final service = _FakeGoalService([_goal('g1')]);
    final provider = GoalProvider(service: service);
    await provider.load();
    service.writeError = ApiException('Bạn đã có 120 từ vựng; số cần đạt phải lớn hơn 120.');

    final error = await provider.create(const GoalDraft(type: GoalType.vocabulary, target: 100));

    expect(error, 'Bạn đã có 120 từ vựng; số cần đạt phải lớn hơn 120.');
    expect(_titles(provider), ['Mục tiêu g1']);
  });

  test('sửa và xoá cập nhật danh sách; xoá lỗi báo qua thông điệp', () async {
    final service = _FakeGoalService([_goal('g1'), _goal('g2')]);
    final provider = GoalProvider(service: service);
    await provider.load();

    expect(await provider.update('g1', const GoalEdit(title: 'Mốc N5', deadline: null)), isNull);
    await provider.delete(provider.state.valueOrNull!.goals.last);
    expect(_titles(provider), ['Mốc N5']);

    service.writeError = ApiException('Không tìm thấy mục tiêu.');
    await provider.delete(provider.state.valueOrNull!.goals.single);
    expect(provider.consumeMessage(), 'Không tìm thấy mục tiêu.');
    expect(_titles(provider), ['Mốc N5']);
  });

  test('rời màn khi đang tải thì phản hồi về sau không gây lỗi', () async {
    final provider = GoalProvider(service: _FakeGoalService([_goal('g1')]));

    final pending = provider.load();
    provider.dispose();

    await expectLater(pending, completes);
  });
}
