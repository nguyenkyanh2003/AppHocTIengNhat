import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/features/srs/models/srs_card.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_progress.dart';
import 'package:apphoctiengnnhat/features/srs/providers/srs_provider.dart';
import 'package:apphoctiengnnhat/features/srs/screens/srs_review_screen.dart';
import 'package:apphoctiengnnhat/features/srs/services/srs_service.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';

final _due = DateTime.utc(2026, 9, 19, 3);

SrsCard _card(String id, String word) => SrsCard.fromJson({
      '_id': 'p-$id',
      'item_id': id,
      'item_type': 'Vocabulary',
      'box': 1,
      'streak': 0,
      'next_review': _due.toIso8601String(),
      'item': {'_id': id, 'word': word, 'hiragana': 'なまえ', 'meaning': 'Tên', 'level': 'N5'},
    });

class _FakeSrsService extends SrsService {
  _FakeSrsService(this._batches);

  final List<List<SrsCard>> _batches;
  final List<bool> answers = [];

  @override
  Future<SrsBatch> fetchDue({List<String> excludeItemIds = const [], int limit = SrsService.defaultLimit}) async =>
      SrsBatch(cards: _batches.isEmpty ? const [] : _batches.removeAt(0), limit: limit);

  @override
  Future<int> fetchDueCount() async => 1;

  @override
  Future<SrsStats> fetchStats() async =>
      const SrsStats(totalCards: 1, dueCount: 0, byBox: {1: 0, 2: 1, 3: 0, 4: 0, 5: 0});

  @override
  Future<SrsProgress> review({
    required String itemId,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) async {
    answers.add(isCorrect);
    return SrsProgress(
      id: 'p-$itemId',
      itemId: itemId,
      itemType: 'Vocabulary',
      box: 2,
      nextReview: _due.add(const Duration(days: 3)),
      streak: 1,
    );
  }
}

Future<_FakeSrsService> _pump(WidgetTester tester, Size size, List<List<SrsCard>> batches) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeSrsService(batches);
  final router = GoRouter(
    initialLocation: '/srs',
    routes: [
      GoRoute(path: '/srs', builder: (context, state) => const SrsReviewScreen()),
      GoRoute(path: '/review', builder: (context, state) => const Text('hub')),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SrsProvider(service: service)),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('the answer is hidden until the card is flipped, then the self-grade buttons appear',
      (tester) async {
    final service = await _pump(tester, const Size(360, 740), [
      [_card('v1', '名前')],
    ]);

    expect(find.text('名前'), findsOneWidget);
    expect(find.text('Tên'), findsNothing);
    expect(find.text('Nhớ'), findsNothing);

    await tester.tap(find.text('Lật thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Tên'), findsOneWidget);

    await tester.tap(find.text('Nhớ'));
    await tester.pumpAndSettle();

    expect(service.answers, [true]);
    expect(find.text('Xong phiên ôn tập'), findsOneWidget);
    expect(find.text('Hộp 2'), findsOneWidget);
  });

  testWidgets('with nothing due the screen says so instead of showing an empty card', (tester) async {
    await _pump(tester, const Size(1280, 800), []);

    expect(find.text('Không có thẻ nào đến hạn'), findsOneWidget);
    expect(find.text('Về trang ôn tập'), findsOneWidget);
  });
}
