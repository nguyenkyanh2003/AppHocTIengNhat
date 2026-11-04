import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/progress/models/dashboard.dart';

void main() {
  test('thống kê tách "Kanji đã học trong bài" khỏi "Kanji đang ôn"', () {
    final stats = DashboardStats.fromJson({'vocabulary_learned': 12, 'kanji_learned': 0, 'kanji_reviewing': 9});

    expect(stats.vocabularyLearned, 12);
    expect(stats.kanjiLearned, 0);
    expect(stats.kanjiReviewing, 9);
  });

  test('server cũ chưa trả kanji_reviewing thì coi là 0', () {
    expect(DashboardStats.fromJson(const {}).kanjiReviewing, 0);
  });
}
