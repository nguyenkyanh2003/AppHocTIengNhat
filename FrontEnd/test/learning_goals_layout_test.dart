import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/goals/models/learning_goal.dart';
import 'package:apphoctiengnnhat/features/goals/screens/learning_goals_screen.dart';
import 'package:apphoctiengnnhat/features/goals/services/goal_service.dart';

class _Service extends GoalService {
  @override
  Future<GoalsSnapshot> list() async => GoalsSnapshot(goals: [
        LearningGoal(id: 'g1', type: GoalType.vocabulary, title: 'Đạt 1500 từ vựng trước kỳ thi JLPT N4 tháng mười hai',
            target: 1500, current: 1234, isCompleted: false, createdAt: DateTime.utc(2026, 11, 1),
            deadline: DateTime.now().add(const Duration(days: 57))),
        LearningGoal(id: 'g2', type: GoalType.kanji, title: 'Kanji', target: 30, current: 30, isCompleted: true,
            completedAt: DateTime.utc(2026, 11, 2), createdAt: DateTime.utc(2026, 11, 1)),
      ], counts: const GoalCounts(vocabulary: 1234, kanji: 30));
}

void main() {
  for (final (name, theme) in [('sáng', () => AppTheme.lightTheme), ('tối', () => AppTheme.darkTheme)]) {
    for (final width in [320.0, 360.0]) {
      testWidgets('$name, rộng ${width.toInt()}: màn và form không tràn khung', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(initialLocation: '/goals', routes: [
          GoRoute(path: '/goals', builder: (context, state) => LearningGoalsScreen(service: _Service())),
        ]);
        await tester.pumpWidget(MaterialApp.router(theme: theme(), routerConfig: router));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Sửa mục tiêu').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
