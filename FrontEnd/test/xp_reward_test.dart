import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/exercise/models/exercise.dart';
import 'package:apphoctiengnnhat/features/exercise/providers/exercise_provider.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_result_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/services/exercise_service.dart';
import 'package:apphoctiengnnhat/features/jlpt/models/jlpt_models.dart';
import 'package:apphoctiengnnhat/features/jlpt/providers/jlpt_exam_provider.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_exam_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/services/jlpt_service.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';
import 'package:apphoctiengnnhat/shared/models/xp_reward.dart';
import 'package:apphoctiengnnhat/shared/widgets/xp_reward_note.dart';

const _resultJson = {
  '_id': 'r1',
  'exercise_id': 'e1',
  'score': 100,
  'correct_answers': 2,
  'total_questions': 2,
  'time_spent': 42,
  'passed': true,
  'createdAt': '2026-11-24T03:00:00.000Z',
};

/// Server giả: kết quả nộp kèm XP, còn đọc lại kết quả theo id thì không (như API thật).
class _ExerciseService extends ExerciseService {
  _ExerciseService(this.xp);

  final Map<String, Object?>? xp;

  @override
  Future<ExerciseResult> submit(String exerciseId,
          {required Map<String, String> answers, required int timeSpent, required String attemptId}) async =>
      ExerciseResult.fromJson({..._resultJson, 'xp': xp});

  @override
  Future<ExerciseResult> result(String id) async => ExerciseResult.fromJson({..._resultJson, '_id': id});
}

class _StreakService extends StreakService {
  int loads = 0;

  @override
  Future<UserStreak> getMyStreak() async {
    loads++;
    return UserStreak.fromJson(const {'current_streak': 1, 'total_xp': 20});
  }
}

const _question = JLPTQuestion(mondai: 1, questionText: 'A', choices: ['1', '2'], correctAnswer: 1);

class _JlptService extends JLPTService {
  @override
  Future<JLPTExamDetail> detail(String id) async =>
      JLPTExamDetail(id: id, title: 'Đề thử', level: 'N5', timeLimit: 30, mojiGoi: const [_question]);

  @override
  Future<JLPTSubmitResult> submit(String id,
          {required String attemptId, required Map<String, int> answers, required int timeSpent}) async =>
      JLPTSubmitResult.fromJson(const {
        'total_score': 120,
        'passed': true,
        'section_scores': {'moji_goi': 40, 'bunpou': 30, 'dokkai': 30, 'choukai': 20},
        'duration': 30,
        'xp': {'awarded': 0, 'remaining': 0},
      });

  @override
  Future<List<JLPTQuestion>> solutions(String id) async => const [_question];
}

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(theme: theme ?? AppTheme.lightTheme, home: Scaffold(body: child));

void main() {
  group('XpReward', () {
    test('đọc XP lượt làm từ phản hồi nộp bài', () {
      final reward = XpReward.fromJson(const {'awarded': 5, 'remaining': 5});
      expect((reward?.awarded, reward?.remaining), (5, 5));
    });

    test('phản hồi không kèm XP (đọc lại từ lịch sử, lượt nộp cũ) thì không có gì để báo', () {
      expect(XpReward.fromJson(null), isNull);
      expect(XpReward.fromJson(const {'remaining': 0}), isNull);
      expect(ExerciseResult.fromJson(_resultJson).xp, isNull);
    });

    test('kết quả bài tập và đề JLPT mang XP của lượt làm', () {
      expect(ExerciseResult.fromJson({..._resultJson, 'xp': {'awarded': 10, 'remaining': 0}}).xp?.awarded, 10);
      expect(JLPTSubmitResult.fromJson(const {'xp': {'awarded': 20, 'remaining': 0}}).xp?.awarded, 20);
    });
  });

  group('XpRewardNote', () {
    Future<void> pumpNote(WidgetTester tester, XpReward reward, {String subject = 'bài này', ThemeData? theme}) =>
        tester.pumpWidget(_host(XpRewardNote(reward: reward, subject: subject), theme: theme));

    testWidgets('chưa đạt lần đầu: +5 XP và còn 5 XP khi làm đạt', (tester) async {
      await pumpNote(tester, const XpReward(awarded: 5, remaining: 5));

      expect(find.text('+5 XP'), findsOneWidget);
      expect(find.text('Làm đạt bài này để nhận thêm 5 XP.'), findsOneWidget);
    });

    testWidgets('nhận đủ ngay lượt này: báo trước là làm lại không cộng thêm', (tester) async {
      await pumpNote(tester, const XpReward(awarded: 20, remaining: 0), subject: 'đề này');

      expect(find.text('+20 XP'), findsOneWidget);
      expect(find.text('Làm lại đề này sẽ không cộng thêm XP.'), findsOneWidget);
    });

    testWidgets('làm lại bài đã nhận đủ: không cộng nhưng vẫn là ngày học', (tester) async {
      await pumpNote(tester, const XpReward(awarded: 0, remaining: 0));

      expect(find.text('Không cộng thêm XP'), findsOneWidget);
      expect(find.text('Bạn đã nhận đủ XP của bài này; lượt này vẫn được tính là ngày học.'), findsOneWidget);
    });

    testWidgets('làm lại vẫn chưa đạt: không cộng, chỉ đường lấy nốt phần còn lại', (tester) async {
      await pumpNote(tester, const XpReward(awarded: 0, remaining: 5), theme: AppTheme.darkTheme);

      expect(find.text('Không cộng thêm XP'), findsOneWidget);
      expect(find.text('Làm đạt bài này để nhận thêm 5 XP.'), findsOneWidget);
    });
  });

  group('màn kết quả bài tập', () {
    Future<ExerciseProvider> pumpResult(WidgetTester tester, {Map<String, Object?>? xp, bool submitFirst = true}) async {
      final provider = ExerciseProvider(service: _ExerciseService(xp));
      if (submitFirst) await provider.submit('e1', answers: const {'q1': 'a1'}, timeSpent: 42, attemptId: 'a-1');
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const ExerciseResultScreen(resultId: 'r1')),
      ));
      await tester.pumpAndSettle();
      return provider;
    }

    testWidgets('ngay sau khi nộp: hiện XP lượt vừa làm', (tester) async {
      await pumpResult(tester, xp: {'awarded': 5, 'remaining': 0});

      expect(find.text('+5 XP'), findsOneWidget);
      expect(find.text('Làm lại bài này sẽ không cộng thêm XP.'), findsOneWidget);
    });

    testWidgets('mở lại một kết quả cũ từ lịch sử: không đoán XP', (tester) async {
      await pumpResult(tester, submitFirst: false);

      expect(find.byType(XpRewardNote), findsNothing);
    });

    test('XP chỉ gắn với đúng kết quả vừa nộp và mất khi đăng xuất', () async {
      final provider = ExerciseProvider(service: _ExerciseService(const {'awarded': 10, 'remaining': 0}));
      await provider.submit('e1', answers: const {'q1': 'a1'}, timeSpent: 42, attemptId: 'a-1');

      expect(provider.rewardOf('r1')?.awarded, 10);
      expect(provider.rewardOf('r2'), isNull);
      provider.clear();
      expect(provider.rewardOf('r1'), isNull);
    });
  });

  testWidgets('nộp đề JLPT: bảng kết quả báo XP và số XP trên app được làm mới', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final streak = _StreakService();
    final exam = JLPTExamProvider(service: _JlptService());
    addTearDown(exam.dispose);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: exam),
        ChangeNotifierProvider(create: (_) => StreakProvider(service: streak)),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const JLPTExamScreen(examId: 'x1', title: 'Đề thử')),
    ));
    await tester.pumpAndSettle();
    exam.setAnswer('moji-0', 0);
    await tester.pump();

    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle();

    expect(find.text('Không cộng thêm XP'), findsOneWidget);
    expect(find.text('Bạn đã nhận đủ XP của đề này; lượt này vẫn được tính là ngày học.'), findsOneWidget);
    expect(streak.loads, 1, reason: 'Trang chủ và hồ sơ phải thấy XP mới ngay');
  });
}
