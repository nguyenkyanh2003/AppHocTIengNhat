import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson_progress.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson_study_step.dart';
import 'package:apphoctiengnnhat/features/lessons/models/quick_quiz.dart';
import 'package:apphoctiengnnhat/features/lessons/providers/lesson_study_session.dart';
import 'package:apphoctiengnnhat/features/lessons/services/lesson_progress_service.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/detail/lesson_roadmap.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/lesson_content_chips.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/study/study_quiz_step.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/study/study_vocabulary_step.dart';

const _words = [
  ('w1', '名前', 'なまえ', 'tên'),
  ('w2', '国', 'くに', 'đất nước'),
  ('w3', '仕事', 'しごと', 'công việc'),
  ('w4', '学生', 'がくせい', 'học sinh'),
  ('w5', '先生', 'せんせい', 'giáo viên'),
  ('w6', '友達', 'ともだち', 'bạn bè'),
];

LessonDetail _detail({bool videos = true, int words = 6, bool dialogue = true}) => LessonDetail.fromJson({
      '_id': 'l1',
      'title': 'Tình huống: Tự giới thiệu',
      'level': 'N5',
      'situation': 'self_introduction',
      'description': 'Chào hỏi khi gặp lần đầu.',
      'can_do_goals': ['Chào hỏi lịch sự'],
      'dialogue': dialogue
          ? [
              {'speaker': 'Linh', 'text_ja': 'はじめまして。', 'reading': 'はじめまして。', 'text_vi': 'Rất vui được gặp.'},
            ]
          : [],
      'videos': videos
          ? [
              {'title': 'Chào buổi sáng', 'url': '/uploads/a.mp4'},
              {'title': 'Làm quen', 'url': '/uploads/b.mp4'},
            ]
          : [],
      'tuvungs': [
        for (final (id, word, kana, meaning) in _words.take(words))
          {'_id': id, 'word': word, 'hiragana': kana, 'meaning': meaning},
      ],
    });

LessonProgress _progress({bool completed = false, List<String> learned = const []}) => LessonProgress.fromJson({
      '_id': 'p1',
      'lesson': 'l1',
      'is_completed': completed,
      'completed_vocabularies': learned.length,
      'total_vocabularies': 6,
      'learned_vocabulary_ids': learned,
    });

/// Service giả: ghi lại lời gọi, trả `null` (như service thật khi lỗi mạng)
/// theo cờ để kiểm đường lỗi.
class _FakeProgressService extends LessonProgressService {
  _FakeProgressService({this.learned = const []});

  final List<String> learned;
  final List<String> updated = [];
  int completions = 0;
  bool failUpdates = false;
  bool failComplete = false;

  @override
  Future<LessonProgress?> startLesson(String lessonId) async => _progress(learned: learned);

  @override
  Future<LessonProgress?> updateProgress({
    required String lessonId,
    required String itemType,
    required String itemId,
    required bool completed,
  }) async {
    updated.add(itemId);
    return failUpdates ? null : _progress(learned: [...learned, itemId]);
  }

  @override
  Future<LessonProgress?> completeLesson(String lessonId) async {
    completions++;
    return failComplete ? null : _progress(completed: true);
  }
}

void main() {
  group('lộ trình học', () {
    test('đi từ mở đầu, từng cảnh video, hội thoại, từ vựng, kiểm tra tới hoàn thành', () {
      final kinds = buildStudySteps(_detail()).map((step) => step.kind).toList();
      expect(kinds, [
        StudyStepKind.intro,
        StudyStepKind.video,
        StudyStepKind.video,
        StudyStepKind.dialogue,
        StudyStepKind.vocabulary,
        StudyStepKind.quiz,
        StudyStepKind.finish,
      ]);
      expect(buildStudySteps(_detail())[2].title, 'Cảnh 2: Làm quen');
    });

    test('chỉ gồm phần bài có: không video, không hội thoại, quá ít từ thì không kiểm tra', () {
      final kinds = buildStudySteps(_detail(videos: false, dialogue: false, words: 3)).map((s) => s.kind);
      expect(kinds, [StudyStepKind.intro, StudyStepKind.vocabulary, StudyStepKind.finish]);
    });

    test('tên bài bỏ tiền tố tình huống, thời lượng ước lượng hợp lý', () {
      expect(_detail().lesson.displayTitle, 'Tự giới thiệu');
      expect(estimateStudyMinutes(_detail()), inInclusiveRange(4, 10));
    });
  });

  group('kiểm tra nhanh', () {
    test('mỗi câu bốn đáp án khác nhau, đúng một đáp án là nghĩa của từ', () {
      final quiz = buildQuickQuiz(_detail().words);
      expect(quiz, hasLength(5));
      for (final question in quiz) {
        expect(question.choices.toSet(), hasLength(4));
        expect(question.choices[question.correctIndex], question.word.meaning);
      }
      // Vị trí đáp án đúng xoay vòng, không luôn ở một chỗ.
      expect(quiz.map((q) => q.correctIndex).toSet().length, greaterThan(1));
    });

    test('tất định và không dựng khi bài có dưới bốn từ', () {
      final words = _detail().words;
      expect(buildQuickQuiz(words).map((q) => q.choices.join()), buildQuickQuiz(words).map((q) => q.choices.join()));
      expect(buildQuickQuiz(words.take(3).toList()), isEmpty);
    });
  });

  group('phiên học', () {
    test('mở bài nạp những từ đã nhớ từ trước', () async {
      final session = LessonStudySession(detail: _detail(), service: _FakeProgressService(learned: ['w1']));
      await session.start();
      expect(session.isLearned(session.detail.words[0]), isTrue);
      expect(session.learnedCount, 1);
    });

    test('bấm "Đã nhớ" lưu đúng một lần kể cả bấm đôi', () async {
      final service = _FakeProgressService();
      final session = LessonStudySession(detail: _detail(), service: service);
      final word = session.detail.words[1];

      await Future.wait([session.markLearned(word), session.markLearned(word)]);

      expect(service.updated, ['w2']);
      expect(session.isLearned(word), isTrue);
    });

    test('lưu từ thất bại thì báo và cho bấm lại', () async {
      final service = _FakeProgressService()..failUpdates = true;
      final session = LessonStudySession(detail: _detail(), service: service);
      final word = session.detail.words[0];

      await session.markLearned(word);

      expect(session.isLearned(word), isFalse);
      expect(session.consumeMessage(), contains('名前'));
      expect(session.consumeMessage(), isNull);
    });

    test('bước kiểm tra chỉ cho đi tiếp khi đã trả lời hết', () async {
      final session = LessonStudySession(detail: _detail(), service: _FakeProgressService(), initialStep: 5);
      expect(session.step.kind, StudyStepKind.quiz);
      expect(session.canContinue, isFalse);

      for (var q = 0; q < session.quiz.length; q++) {
        session.answer(q, session.quiz[q].correctIndex);
      }
      session.answer(0, 3); // Trả lời lại không đổi câu đã chọn.

      expect(session.canContinue, isTrue);
      expect(session.correctAnswers, session.quiz.length);
    });

    test('tới bước cuối thì lưu hoàn thành bài, lỗi thì thử lại được', () async {
      final service = _FakeProgressService()..failComplete = true;
      final session = LessonStudySession(detail: _detail(videos: false, dialogue: false, words: 3), service: service, initialStep: 1);

      await session.next();
      expect(session.isFinished, isTrue);
      expect(session.completion, isA<ViewFailure<LessonProgress>>());

      service.failComplete = false;
      await session.complete();
      expect(session.completion.valueOrNull?.isCompleted, isTrue);
      expect(service.completions, 2);
    });

    test('mở thẳng một bước không vượt quá bước cuối cùng có nội dung', () {
      final session = LessonStudySession(detail: _detail(), service: _FakeProgressService(), initialStep: 99);
      expect(session.step.kind, StudyStepKind.quiz);
    });
  });

  group('giao diện', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

    testWidgets('chip nội dung không hiện loại bài không có', (tester) async {
      await tester.pumpWidget(host(LessonContentChips(detail: _detail())));
      expect(find.text('2 cảnh video'), findsOneWidget);
      expect(find.text('6 từ vựng'), findsOneWidget);
      expect(find.textContaining('chữ Hán'), findsNothing);
      expect(find.textContaining('ngữ pháp'), findsNothing);
    });

    testWidgets('lộ trình liệt kê đủ bước và mở đúng bước được chạm', (tester) async {
      int? opened;
      await tester.pumpWidget(host(LessonRoadmap(
        detail: _detail(),
        progress: _progress(learned: ['w1', 'w2']),
        onOpenStep: (step) => opened = step,
      )));

      expect(find.text('Cảnh 1: Chào buổi sáng'), findsOneWidget);
      expect(find.text('2/6 từ đã nhớ'), findsOneWidget);
      await tester.tap(find.text('Hội thoại'));
      expect(opened, 3);
    });

    testWidgets('thẻ từ ẩn nghĩa cho tới khi lật, "Đã nhớ" chuyển sang từ kế', (tester) async {
      final learned = <String>{};
      final words = _detail().words;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => StudyVocabularyStep(
          words: words,
          isLearned: (word) => learned.contains(word.id),
          isSaving: (_) => false,
          onMarkLearned: (word) async => setState(() => learned.add(word.id)),
        ),
      )));

      expect(find.text('tên'), findsNothing);
      await tester.tap(find.text('名前'));
      await tester.pumpAndSettle();
      expect(find.text('tên'), findsOneWidget);

      await tester.tap(find.text('Đã nhớ'));
      await tester.pumpAndSettle();
      expect(learned, {'w1'});
      expect(find.text('Từ 2/6'), findsOneWidget);
    });

    testWidgets('chọn đáp án là biết ngay đúng hay sai', (tester) async {
      final quiz = buildQuickQuiz(_detail().words);
      final answers = <int, int>{};
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => StudyQuizStep(
          questions: quiz.take(1).toList(),
          answerOf: (q) => answers[q],
          onAnswer: (q, choice) => setState(() => answers[q] = choice),
        ),
      )));

      final wrong = (quiz.first.correctIndex + 1) % 4;
      await tester.tap(find.text(quiz.first.choices[wrong]));
      await tester.pump();
      expect(find.textContaining('Chưa đúng'), findsOneWidget);
    });
  });
}
