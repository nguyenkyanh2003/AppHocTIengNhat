import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/study_groups/models/study_group.dart';

StudyGroup _groupWith(String? avatar) => StudyGroup.fromJson({
      '_id': 'g1',
      'name': 'Nhóm',
      'creator_id': 'u1',
      'avatar': avatar,
      'created_at': '2026-11-05T00:00:00.000Z',
      'updated_at': '2026-11-05T00:00:00.000Z',
    });

void main() {
  group('ảnh nhóm', () {
    test('ảnh mẫu backend gán sẵn được coi như chưa có ảnh', () {
      expect(_groupWith('https://via.placeholder.com/150').avatar, isNull);
    });

    test('ảnh thật giữ nguyên', () {
      const url = 'https://cdn.example.com/group.png';
      expect(_groupWith(url).avatar, url);
    });

    test('không có ảnh thì trả về null', () {
      expect(_groupWith(null).avatar, isNull);
    });
  });
}
