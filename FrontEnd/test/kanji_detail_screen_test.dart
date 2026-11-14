import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/kanji/models/kanji.dart';
import 'package:apphoctiengnnhat/features/kanji/screens/kanji_detail_screen.dart';
import 'package:apphoctiengnnhat/features/kanji/services/kanji_service.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_progress.dart';

final _progress = SrsProgress(
  id: 'p1',
  itemId: 'k1',
  itemType: SrsProgress.itemTypeKanji,
  box: 1,
  nextReview: DateTime.utc(2026, 11, 5, 3),
  streak: 0,
);

class _FakeKanjiService extends KanjiService {
  final List<String> calls = [];
  bool inReview = false;

  @override
  Future<Kanji> detail(String id) async => Kanji(
        id: id,
        character: '学',
        hanviet: 'Học',
        meaning: 'Học, học tập',
        onyomi: const ['ガク'],
        kunyomi: const ['まな.ぶ'],
        srsProgress: inReview ? _progress : null,
      );

  @override
  Future<SrsProgress> addToReview(String id) async {
    calls.add('add $id');
    inReview = true;
    return _progress;
  }

  @override
  Future<void> removeFromReview(String id) async {
    calls.add('remove $id');
    inReview = false;
  }
}

Future<_FakeKanjiService> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeKanjiService();
  await tester.pumpWidget(MaterialApp(home: KanjiDetailScreen(kanjiId: 'k1', service: service)));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('chữ chưa có thẻ ôn thì nút là "Thêm vào ôn tập", bấm xong thành "Đã thêm"', (tester) async {
    final service = await _pump(tester);

    expect(find.text('Học, học tập'), findsOneWidget);
    expect(find.text('ガク'), findsOneWidget);

    await tester.tap(find.text('Thêm vào ôn tập'));
    await tester.pumpAndSettle();

    expect(service.calls, ['add k1']);
    expect(find.text('Đã thêm vào ôn tập'), findsOneWidget);
    expect(find.textContaining('Hộp 1/5'), findsOneWidget);
  });

  testWidgets('gỡ khỏi lịch ôn phải xác nhận trước, huỷ thì không gọi gì', (tester) async {
    final service = await _pump(tester);
    await tester.tap(find.text('Thêm vào ôn tập'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đã thêm vào ôn tập'));
    await tester.pumpAndSettle();
    expect(find.text('Gỡ khỏi lịch ôn?'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(service.calls, ['add k1']);

    await tester.tap(find.text('Đã thêm vào ôn tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gỡ'));
    await tester.pumpAndSettle();

    expect(service.calls, ['add k1', 'remove k1']);
    expect(find.text('Thêm vào ôn tập'), findsOneWidget);
  });
}
