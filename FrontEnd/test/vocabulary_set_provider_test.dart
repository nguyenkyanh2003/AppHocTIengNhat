import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary_set.dart';
import 'package:apphoctiengnnhat/features/vocabulary/providers/vocabulary_set_provider.dart';
import 'package:apphoctiengnnhat/features/vocabulary/services/vocabulary_service.dart';
import 'package:apphoctiengnnhat/features/vocabulary/widgets/vocabulary_sets_tab.dart';

VocabularySet _set(String id,
        {String level = 'N5', String? section, int learned = 0}) =>
    VocabularySet(
      id: id,
      level: level,
      title: 'Bộ $id',
      section: section,
      part: 1,
      partCount: 1,
      wordCount: 2,
      learnedCount: learned,
    );

Vocabulary _word(String id, {bool learned = false}) => Vocabulary(
      id: id,
      word: 'từ $id',
      hiragana: 'kana',
      meaning: 'nghĩa',
      isLearned: learned,
    );

/// Service giả; mỗi lần hỏi danh sách bộ trả về một [Completer] để test tự
/// quyết định phản hồi nào về trước.
class _FakeService extends VocabularyService {
  final Map<String, Completer<List<VocabularySet>>> setRequests = {};
  VocabularySetDetail? detail;
  final List<String> marked = [];
  final List<String> unmarked = [];
  Object? markError;

  @override
  Future<List<VocabularySet>> getSets(String level) =>
      (setRequests[level] = Completer<List<VocabularySet>>()).future;

  @override
  Future<VocabularySetDetail> getSet(String setId) async => detail!;

  @override
  Future<void> markAsLearned(String vocabularyId) async {
    if (markError != null) throw markError!;
    marked.add(vocabularyId);
  }

  @override
  Future<void> unmarkAsLearned(String vocabularyId) async {
    unmarked.add(vocabularyId);
  }
}

void main() {
  group('model', () {
    test('đọc JSON của backend và tính tiêu đề, tiến độ', () {
      final set = VocabularySet.fromJson({
        'id': 'N5.food.2',
        'level': 'N5',
        'title': 'Ăn uống',
        'section': null,
        'part': 2,
        'partCount': 4,
        'wordCount': 20,
        'learnedCount': 5,
      });

      expect(set.displayTitle, 'Ăn uống · Phần 2/4');
      expect(set.progress, 0.25);
      expect(set.isCompleted, isFalse);
    });

    test('bộ chỉ một phần không ghi "Phần 1/1"', () {
      expect(_set('N5.time.1').displayTitle, 'Bộ N5.time.1');
    });
  });

  group('provider', () {
    test('lấy cấp mặc định theo trình độ, chỉ khi chưa tải lần nào', () async {
      final service = _FakeService();
      final provider = VocabularySetProvider(service: service)
        ..useDefaultLevel('N3');
      expect(provider.level, 'N3');

      final loading = provider.loadSets();
      service.setRequests['N3']!.complete([]);
      await loading;

      provider.useDefaultLevel('N1');
      expect(provider.level, 'N3');
    });

    test('phản hồi của cấp cũ về muộn không đè cấp mới', () async {
      final service = _FakeService();
      final provider = VocabularySetProvider(service: service);

      final first = provider.selectLevel('N4');
      final second = provider.selectLevel('N2');
      service.setRequests['N2']!.complete([_set('N2.1.n.1', level: 'N2')]);
      service.setRequests['N4']!.complete([_set('N4.work.1', level: 'N4')]);
      await Future.wait([first, second]);

      expect(provider.level, 'N2');
      expect(provider.setsState.valueOrNull!.single.id, 'N2.1.n.1');
    });

    test('đánh dấu cả bộ chỉ gửi những từ chưa học', () async {
      final service = _FakeService()
        ..detail = VocabularySetDetail(
          set: _set('N5.food.1'),
          words: [_word('a', learned: true), _word('b'), _word('c')],
        );
      final provider = VocabularySetProvider(service: service);
      await provider.loadSet('N5.food.1');

      final count = await provider.markCurrentSetLearned();

      expect(count, 2);
      expect(service.marked, ['b', 'c']);
      expect(provider.isMarking, isFalse);
    });

    test('bỏ đánh dấu cả bộ chỉ gửi những từ đã học', () async {
      final service = _FakeService()
        ..detail = VocabularySetDetail(
          set: _set('N5.food.1', learned: 2),
          words: [
            _word('a', learned: true),
            _word('b'),
            _word('c', learned: true)
          ],
        );
      final provider = VocabularySetProvider(service: service);
      await provider.loadSet('N5.food.1');

      expect(await provider.unmarkCurrentSetLearned(), 2);
      expect(service.unmarked, ['a', 'c']);
      expect(service.marked, isEmpty);
    });

    test('đổi trạng thái một từ gửi đúng lệnh theo trạng thái hiện tại',
        () async {
      final learned = _word('a', learned: true);
      final fresh = _word('b');
      final service = _FakeService()
        ..detail = VocabularySetDetail(
          set: _set('N5.food.1', learned: 1),
          words: [learned, fresh],
        );
      final provider = VocabularySetProvider(service: service);
      await provider.loadSet('N5.food.1');

      await provider.toggleWordLearned(learned);
      await provider.toggleWordLearned(fresh);

      expect(service.unmarked, ['a']);
      expect(service.marked, ['b']);
    });

    test('lỗi giữa chừng được ném ra và cờ đang đánh dấu được tắt', () async {
      final service = _FakeService()
        ..detail = VocabularySetDetail(set: _set('N5.food.1'), words: [
          _word('a'),
        ])
        ..markError = NetworkException('mất mạng');
      final provider = VocabularySetProvider(service: service);
      await provider.loadSet('N5.food.1');

      await expectLater(provider.markCurrentSetLearned(), throwsA(anything));
      expect(provider.isMarking, isFalse);
    });
  });

  testWidgets('tab bộ từ vựng hiện tiêu đề mức độ khó và thẻ bộ',
      (tester) async {
    final service = _FakeService();
    final provider = VocabularySetProvider(service: service)
      ..useDefaultLevel('N3');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: VocabularySetsTab())),
      ),
    );
    final loading = provider.loadSets();
    service.setRequests['N3']!.complete([
      _set('N3.1.n.1', level: 'N3', section: 'Cơ bản', learned: 2),
      _set('N3.2.n.1', level: 'N3', section: 'Trung bình'),
    ]);
    await loading;
    await tester.pumpAndSettle();

    expect(find.text('Cơ bản'), findsOneWidget);
    expect(find.text('Trung bình'), findsOneWidget);
    expect(find.text('2/2 từ đã học'), findsOneWidget);
    expect(find.text('2 bộ · đã học 2/4 từ'), findsOneWidget);
  });
}
