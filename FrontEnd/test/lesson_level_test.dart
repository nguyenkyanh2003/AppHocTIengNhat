import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/lessons/models/lesson_level.dart';

void main() {
  group('defaultLessonLevel', () {
    test('dùng đúng trình độ trong hồ sơ', () {
      expect(defaultLessonLevel('N4'), 'N4');
      expect(defaultLessonLevel('N2'), 'N2');
    });

    test('chấp nhận chữ thường, khoảng trắng và dạng số của hồ sơ cũ', () {
      expect(defaultLessonLevel(' n3 '), 'N3');
      expect(defaultLessonLevel('5'), 'N5');
    });

    test('người học N1 bắt đầu ở N2 vì chưa có bài N1', () {
      expect(defaultLessonLevel('N1'), 'N2');
    });

    test('hồ sơ thiếu hoặc sai định dạng bắt đầu từ N5', () {
      expect(defaultLessonLevel(null), 'N5');
      expect(defaultLessonLevel(''), 'N5');
      expect(defaultLessonLevel('beginner'), 'N5');
      expect(defaultLessonLevel('N9'), 'N5');
    });
  });
}
