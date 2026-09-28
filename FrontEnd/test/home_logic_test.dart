import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/home/models/next_lesson.dart';
import 'package:apphoctiengnnhat/features/home/services/home_service.dart';
import 'package:apphoctiengnnhat/features/home/widgets/home_greeting.dart';
import 'package:apphoctiengnnhat/features/home/widgets/home_stat_cards.dart';
import 'package:apphoctiengnnhat/features/home/widgets/next_lesson_card.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';

Lesson _lesson(String id, int order) => Lesson.fromJson({
      '_id': id,
      'title': 'Bài $order',
      'level': 'N4',
      'order': order,
      'createdAt': '2026-09-01T00:00:00Z',
      'updatedAt': '2026-09-01T00:00:00Z',
    });

LessonProgressSummary _progress(String id, {required bool done, required int day}) =>
    LessonProgressSummary(lessonId: id, isCompleted: done, lastStudiedAt: DateTime(2026, 9, day));

final _lessons = [for (var i = 1; i <= 5; i++) _lesson('l$i', i)];

void main() {
  group('chọn bài học tiếp theo', () {
    test('chưa học bài nào: bài đầu tiên của trình độ', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: const [])!;
      expect(next.lesson!.id, 'l1');
      expect(next.inProgress, isFalse);
      expect((next.completedInLevel, next.totalInLevel), (0, 5));
    });

    test('bài gần nhất đang học dở: học tiếp chính bài đó', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: [
        _progress('l1', done: true, day: 1),
        _progress('l3', done: false, day: 5),
      ])!;
      expect(next.lesson!.id, 'l3');
      expect(next.inProgress, isTrue);
      expect(next.completedInLevel, 1);
    });

    test('bài gần nhất đã xong: bài chưa xong đầu tiên đứng sau nó', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: [
        _progress('l2', done: true, day: 3),
        _progress('l4', done: true, day: 2),
      ])!;
      expect(next.lesson!.id, 'l3');
      expect(next.completedInLevel, 2);
    });

    test('bài cuối đã xong mà còn bài bỏ dở phía trước: quay về bài chưa xong đầu tiên', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: [
        _progress('l5', done: true, day: 9),
      ])!;
      expect(next.lesson!.id, 'l1');
    });

    test('xong hết: không còn bài nào, tiến độ đầy', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: [
        for (final lesson in _lessons) _progress(lesson.id, done: true, day: lesson.order),
      ])!;
      expect(next.levelFinished, isTrue);
      expect(next.levelProgress, 1);
    });

    test('tiến độ của bài trình độ khác không bị tính', () {
      final next = pickNextLesson(level: 'N4', lessons: _lessons, progress: [
        _progress('n5-bai-1', done: true, day: 20),
      ])!;
      expect(next.lesson!.id, 'l1');
      expect(next.completedInLevel, 0);
    });

    test('trình độ không có bài: null', () {
      expect(pickNextLesson(level: 'N2', lessons: const [], progress: const []), isNull);
    });

    test('đọc tiến độ từ API, bỏ dòng có bài đã bị xoá', () {
      expect(LessonProgressSummary.tryParse({'lesson': null, 'is_completed': true}), isNull);
      final entry = LessonProgressSummary.tryParse({
        'lesson': {'_id': 'l2', 'level': 'N4'},
        'is_completed': true,
        'last_studied_at': '2026-09-27T19:00:27.000Z',
      })!;
      expect((entry.lessonId, entry.isCompleted), ('l2', true));
    });
  });

  test('lời chào theo buổi', () {
    expect(greetingPeriod(DateTime(2026, 9, 27, 6)), GreetingPeriod.morning);
    expect(greetingPeriod(DateTime(2026, 9, 27, 11)), GreetingPeriod.afternoon);
    expect(greetingPeriod(DateTime(2026, 9, 27, 18)), GreetingPeriod.evening);
    expect(greetingPeriod(DateTime(2026, 9, 27, 2)), GreetingPeriod.evening);
  });

  test('số hàng nghìn dùng dấu chấm', () {
    expect(formatThousands(24), '24');
    expect(formatThousands(1073), '1.073');
    expect(formatThousands(1234567), '1.234.567');
    expect(formatThousands(0), '0');
  });

  test('tên bài bỏ tiền tố "Tình huống:"', () {
    expect(lessonDisplayTitle('Tình huống: Hỏi đường'), 'Hỏi đường');
    expect(lessonDisplayTitle('Bài học khác'), 'Bài học khác');
  });

  test('từ của ngày: đổi theo ngày, giữ nguyên trong ngày', () {
    expect(dayNumber(DateTime(2026, 9, 27, 0, 1)), dayNumber(DateTime(2026, 9, 27, 23, 59)));
    expect(dayNumber(DateTime(2026, 9, 28)), dayNumber(DateTime(2026, 9, 27)) + 1);
  });
}
