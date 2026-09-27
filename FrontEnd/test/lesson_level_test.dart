import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/lessons/models/lesson_level.dart';

void main() {
  group('defaultLessonLevel', () {
    test('dùng đúng trình độ trong hồ sơ', () {
      expect(defaultLessonLevel('N4'), 'N4');
      expect(defaultLessonLevel('N3'), 'N3');
    });

    test('chấp nhận chữ thường, khoảng trắng và dạng số của hồ sơ cũ', () {
      expect(defaultLessonLevel(' n3 '), 'N3');
      expect(defaultLessonLevel('5'), 'N5');
    });

    test('người học N2, N1 bắt đầu ở N3 — cấp cao nhất có bài tình huống', () {
      expect(defaultLessonLevel('N2'), 'N3');
      expect(defaultLessonLevel('N1'), 'N3');
    });

    test('hàng lọc chỉ có các cấp có bài tình huống', () {
      expect(kLessonLevels, ['N5', 'N4', 'N3']);
    });

    test('hồ sơ thiếu hoặc sai định dạng bắt đầu từ N5', () {
      expect(defaultLessonLevel(null), 'N5');
      expect(defaultLessonLevel(''), 'N5');
      expect(defaultLessonLevel('beginner'), 'N5');
      expect(defaultLessonLevel('N9'), 'N5');
    });
  });

  group('normalizeJlptLevel', () {
    test('chuẩn hoá trình độ trong hồ sơ về N5–N1, giữ nguyên N1', () {
      expect(normalizeJlptLevel('N4'), 'N4');
      expect(normalizeJlptLevel(' n1 '), 'N1');
      expect(normalizeJlptLevel('3'), 'N3');
    });

    test('giá trị thiếu hoặc lạ trả null', () {
      expect(normalizeJlptLevel(null), isNull);
      expect(normalizeJlptLevel(''), isNull);
      expect(normalizeJlptLevel('N9'), isNull);
      expect(normalizeJlptLevel('beginner'), isNull);
    });
  });
}
