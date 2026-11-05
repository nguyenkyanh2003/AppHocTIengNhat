import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/goals/models/learning_goal.dart';
import 'package:apphoctiengnnhat/features/goals/screens/learning_goals_screen.dart';
import 'package:apphoctiengnnhat/features/goals/services/goal_service.dart';

final _today = DateTime.now();

LearningGoal _goal(String id, GoalType type, {required int target, required int current, DateTime? deadline}) => LearningGoal(
      id: id,
      type: type,
      title: 'Mục tiêu $id',
      target: target,
      current: current,
      isCompleted: current >= target,
      completedAt: current >= target ? DateTime.utc(2026, 11, 2) : null,
      deadline: deadline,
      createdAt: DateTime.utc(2026, 11, 1),
    );

/// Service giả lưu trong bộ nhớ, đếm số lần tải danh sách.
class _FakeGoalService extends GoalService {
  _FakeGoalService(this.goals);

  final List<LearningGoal> goals;
  final drafts = <GoalDraft>[];
  final edits = <GoalEdit>[];
  int lists = 0;

  @override
  Future<GoalsSnapshot> list() async {
    lists++;
    return GoalsSnapshot(
      goals: List.of(goals),
      counts: const GoalCounts(lessons: 3, vocabulary: 120, kanji: 5),
      available: const GoalAvailability(lessons: 40, kanji: 33),
    );
  }

  @override
  Future<LearningGoal> create(GoalDraft draft) async {
    drafts.add(draft);
    final goal = _goal('g${goals.length + 1}', draft.type, target: draft.target, current: 5);
    goals.insert(0, goal);
    return goal;
  }

  @override
  Future<LearningGoal> update(String id, GoalEdit edit) async {
    edits.add(edit);
    return goals.firstWhere((goal) => goal.id == id);
  }

  @override
  Future<void> delete(String id) async => goals.removeWhere((goal) => goal.id == id);
}

Future<void> _pump(WidgetTester tester, _FakeGoalService service) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/goals',
    routes: [
      GoRoute(path: '/goals', builder: (context, state) => LearningGoalsScreen(service: service)),
      for (final path in ['/lessons', '/vocabulary', '/kanji'])
        GoRoute(path: path, builder: (context, state) => Scaffold(appBar: AppBar(), body: Text('mở $path'))),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router));
  await tester.pumpAndSettle();
}

Future<void> _openCreateForm(WidgetTester tester) async {
  await tester.tap(find.text('Thêm mục tiêu').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chưa có mục tiêu: hướng dẫn và nút thêm', (tester) async {
    await _pump(tester, _FakeGoalService([]));

    expect(find.text('Chưa có mục tiêu nào'), findsOneWidget);
    expect(find.text('Thêm mục tiêu'), findsOneWidget);
  });

  testWidgets('thẻ hiện tiến độ, phần còn lại, hạn, quá hạn và hoàn thành', (tester) async {
    await _pump(tester, _FakeGoalService([
      _goal('g1', GoalType.vocabulary, target: 150, current: 120, deadline: _today.add(const Duration(days: 10))),
      _goal('g2', GoalType.kanji, target: 10, current: 5, deadline: _today.subtract(const Duration(days: 1))),
      _goal('g3', GoalType.lessons, target: 3, current: 3),
    ]));

    expect(find.text('120/150 từ vựng'), findsOneWidget);
    expect(find.text('Còn 30 từ vựng'), findsOneWidget);
    expect(find.textContaining('còn 10 ngày'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
    expect(find.textContaining('Hoàn thành'), findsOneWidget);
    expect(find.text('Đã đạt 1/3 mục tiêu'), findsOneWidget);
    expect(find.text('Học bài tiếp'), findsNothing, reason: 'mục tiêu đã xong không cần nút học');
  });

  testWidgets('nút học dẫn tới màn học tương ứng; quay về thì tải lại tiến độ', (tester) async {
    final service = _FakeGoalService([_goal('g1', GoalType.vocabulary, target: 150, current: 120)]);
    await _pump(tester, service);
    final loadsBefore = service.lists;

    await tester.tap(find.text('Học từ vựng'));
    await tester.pumpAndSettle();
    expect(find.text('mở /vocabulary'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(service.lists, loadsBefore + 1);
  });

  testWidgets('mục tiêu Kanji dẫn tới bài học — nơi "Đã nhớ" chữ Hán mới tính là đã học', (tester) async {
    final service = _FakeGoalService([_goal('g1', GoalType.kanji, target: 10, current: 5)]);
    await _pump(tester, service);
    expect(find.text('Bấm "Đã nhớ" ở bước Chữ Hán trong bài để tăng tiến độ.'), findsOneWidget);

    await tester.tap(find.text('Học Kanji trong bài'));
    await tester.pumpAndSettle();

    expect(find.text('mở /lessons'), findsOneWidget);
  });

  testWidgets('form chặn số không hợp lệ; đổi loại thì số đang có và trần đổi theo', (tester) async {
    final service = _FakeGoalService([]);
    await _pump(tester, service);
    await _openCreateForm(tester);
    final targetField = find.widgetWithText(TextFormField, 'Số cần đạt');
    expect(find.text('Bạn đang có 120 từ vựng'), findsOneWidget);

    Future<void> chooseType(String label) async {
      await tester.tap(find.byType(DropdownButtonFormField<GoalType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    Future<void> submit(String text) async {
      await tester.enterText(targetField, text);
      await tester.tap(find.text('Thêm'));
      await tester.pump();
    }

    await chooseType('Kanji');
    expect(find.text('Bạn đang có 5 chữ Kanji · các bài học có 33 chữ'), findsOneWidget);

    await submit('abc');
    expect(find.text('Vui lòng nhập số cần đạt.'), findsOneWidget);

    await submit('3');
    expect(find.text('Hãy đặt số lớn hơn 5.'), findsOneWidget);

    // Đã bấm gửi: đổi loại thì kiểm lại ngay theo số đang có của loại mới.
    await chooseType('Từ vựng');
    expect(find.text('Hãy đặt số lớn hơn 120.'), findsOneWidget);
    await chooseType('Kanji');

    await submit('34');
    expect(find.text('Các bài học hiện chỉ có 33 chữ Kanji.'), findsOneWidget);

    await tester.enterText(targetField, '10');
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();

    expect(service.drafts.single.type, GoalType.kanji);
    expect(service.drafts.single.target, 10);
    expect(service.drafts.single.deadline, isNull);
    expect(find.text('Mục tiêu g1'), findsOneWidget, reason: 'đóng form và tải lại danh sách');
  });

  testWidgets('chọn hạn hoàn thành rồi tạo', (tester) async {
    final service = _FakeGoalService([]);
    await _pump(tester, service);
    await _openCreateForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Số cần đạt'), '200');
    await tester.tap(find.text('Chọn hạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hạn: '), findsOneWidget);

    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();

    final deadline = service.drafts.single.deadline!;
    expect(deadline.isBefore(DateTime(_today.year, _today.month, _today.day)), isFalse);
  });

  testWidgets('sửa mục tiêu đã hoàn thành: không đổi được số cần đạt', (tester) async {
    final service = _FakeGoalService([_goal('g1', GoalType.lessons, target: 3, current: 3)]);
    await _pump(tester, service);

    await tester.tap(find.byTooltip('Sửa mục tiêu'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Số cần đạt'));
    expect(field.enabled, isFalse);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(service.edits.single.target, isNull);
  });

  testWidgets('xoá có hỏi xác nhận', (tester) async {
    final service = _FakeGoalService([_goal('g1', GoalType.kanji, target: 10, current: 5)]);
    await _pump(tester, service);

    await tester.tap(find.byTooltip('Xoá mục tiêu'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá mục tiêu?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Xoá'));
    await tester.pumpAndSettle();

    expect(service.goals, isEmpty);
    expect(find.text('Chưa có mục tiêu nào'), findsOneWidget);
  });
}
