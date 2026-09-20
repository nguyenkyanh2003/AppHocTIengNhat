import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/utils/attempt_id.dart';

void main() {
  test('đúng dạng UUID phiên bản 4 mà server kiểm', () {
    final id = newAttemptId();

    expect(
      id,
      matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )),
    );
  });

  test('mỗi lượt làm một ID khác nhau', () {
    final ids = List.generate(500, (_) => newAttemptId()).toSet();

    expect(ids.length, 500, reason: 'ID trùng nhau sẽ bị server coi là gửi lại bài cũ');
  });

  test('bit phiên bản và biến thể được đặt kể cả khi nguồn ngẫu nhiên trả toàn 0', () {
    final id = newAttemptId(_ConstantRandom(0));

    expect(id, '00000000-0000-4000-8000-000000000000');
  });
}

/// Nguồn ngẫu nhiên cố định, để kiểm hai nhóm bit bắt buộc của UUID v4.
class _ConstantRandom implements Random {
  _ConstantRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
