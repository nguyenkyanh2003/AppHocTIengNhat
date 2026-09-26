import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';
import 'package:apphoctiengnnhat/features/lessons/models/dialogue_turn.dart';
import 'package:apphoctiengnnhat/features/lessons/models/situation_labels.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/dialogue_view.dart';

void main() {
  group('Lesson.fromJson với nội dung tình huống', () {
    test('đọc được situation, dialogue và can_do_goals', () {
      final lesson = Lesson.fromJson({
        '_id': 'l1',
        'title': 'Tình huống: Đi siêu thị',
        'level': 'N5',
        'situation': 'supermarket',
        'can_do_goals': ['Hỏi được giá của một món hàng'],
        'dialogue': [
          {
            'speaker': 'Khách',
            'text_ja': 'これはいくらですか。',
            'reading': 'これはいくらですか。',
            'text_vi': 'Cái này bao nhiêu tiền ạ?',
            'audio_url': null,
          },
        ],
      });

      expect(lesson.situation, 'supermarket');
      expect(lesson.hasDialogue, isTrue);
      expect(lesson.dialogue.single.textVi, 'Cái này bao nhiêu tiền ạ?');
      expect(lesson.canDoGoals, ['Hỏi được giá của một món hàng']);
    });

    test('bài ngữ pháp cũ không có dialogue vẫn parse được', () {
      final lesson = Lesson.fromJson({
        '_id': 'l2',
        'title': 'Bài 7: Thể て',
        'level': 'N3',
        'content_html': '<p>Thể て</p>',
      });

      expect(lesson.situation, isNull);
      expect(lesson.hasDialogue, isFalse);
      expect(lesson.dialogue, isEmpty);
      expect(lesson.canDoGoals, isEmpty);
    });

    test('dialogue sai kiểu không làm sập parse', () {
      final lesson = Lesson.fromJson({
        '_id': 'l3',
        'title': 'Bài lỗi',
        'level': 'N5',
        'dialogue': 'không phải mảng',
        'can_do_goals': 'không phải mảng',
      });

      expect(lesson.dialogue, isEmpty);
      expect(lesson.canDoGoals, isEmpty);
    });
  });

  group('situationLabel', () {
    test('dịch mã sang nhãn tiếng Việt', () {
      expect(situationLabel('supermarket'), 'Đi siêu thị');
      expect(situationLabel('train'), 'Đi tàu');
    });

    test('mã lạ trả về chính nó thay vì rỗng', () {
      expect(situationLabel('mã_chưa_có'), 'mã_chưa_có');
    });
  });

  group('DialogueView', () {
    const turns = [
      DialogueTurn(
        speaker: 'Nhân viên',
        textJa: 'いらっしゃいませ。',
        reading: 'いらっしゃいませ。',
        textVi: 'Kính chào quý khách.',
      ),
      DialogueTurn(
        speaker: 'Khách',
        textJa: '牛乳はどこですか。',
        reading: 'ぎゅうにゅうはどこですか。',
        textVi: 'Sữa tươi ở đâu ạ?',
      ),
    ];

    testWidgets('hiển thị đủ lượt thoại và mục tiêu can-do', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DialogueView(
              dialogue: turns,
              canDoGoals: ['Hỏi được món hàng ở đâu'],
            ),
          ),
        ),
      ));

      expect(find.text('いらっしゃいませ。'), findsOneWidget);
      expect(find.text('Sữa tươi ở đâu ạ?'), findsOneWidget);
      expect(find.text('Hỏi được món hàng ở đâu'), findsOneWidget);
      expect(find.text('Hội thoại'), findsOneWidget);
    });

    testWidgets('không có can-do goals thì không hiện khối đó', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DialogueView(dialogue: turns),
          ),
        ),
      ));

      expect(find.text('Sau bài này bạn làm được'), findsNothing);
      expect(find.text('Hội thoại'), findsOneWidget);
    });

    testWidgets('reading trùng text_ja thì không hiện lặp hai lần',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DialogueView(
            dialogue: [
              DialogueTurn(
                speaker: 'Khách',
                textJa: 'ありがとう。',
                reading: 'ありがとう。',
                textVi: 'Cảm ơn.',
              ),
            ],
          ),
        ),
      ));

      expect(find.text('ありがとう。'), findsOneWidget);
    });
  });
}
