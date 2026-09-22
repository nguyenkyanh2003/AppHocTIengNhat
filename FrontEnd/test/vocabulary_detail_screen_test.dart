import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_detail_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/services/vocabulary_service.dart';

final _word = Vocabulary.fromJson({
  '_id': 'v1',
  'word': '名前',
  'hiragana': 'なまえ',
  'meaning': 'Tên',
  'hanviet': 'DANH TIỀN',
  'level': 'N5',
  'isLearned': false,
  'examples': [
    {'sentence': 'お名前は何ですか。', 'meaning': 'Tên bạn là gì?'},
  ],
  'kanjiBreakdown': [
    {'character': '名', 'hanviet': 'DANH'},
    {'character': '前', 'hanviet': 'TIỀN'},
  ],
  'relatedWords': [
    {'_id': 'v2', 'word': '午前', 'hiragana': 'ごぜん', 'meaning': 'Buổi sáng'},
  ],
});

class _FakeService extends VocabularyService {
  final List<String> marked = [];

  @override
  Future<Vocabulary> getVocabularyById(String id) async => marked.contains(id)
      ? _word.copyWith(isLearned: true, reviewBox: 1)
      : _word;

  @override
  Future<void> markAsLearned(String vocabularyId) async =>
      marked.add(vocabularyId);
}

Future<_FakeService> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeService();
  final router = GoRouter(
    initialLocation: '/vocabulary/v1',
    routes: [
      GoRoute(
        path: '/vocabulary/:id',
        builder: (context, state) =>
            VocabularyDetailScreen(vocabularyId: state.pathParameters['id']!),
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => VocabularyProvider(service: service),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('tiêu đề không lặp mặt chữ, có đủ các khối nội dung',
      (tester) async {
    await _pump(tester, const Size(1400, 1200));

    expect(find.text('Chi tiết từ vựng'), findsOneWidget);
    expect(find.text('名前'), findsOneWidget);
    expect(find.byTooltip('Nghe phát âm'), findsOneWidget);
    expect(find.text('Phân tích chữ Hán'), findsOneWidget);
    expect(find.text('DANH'), findsOneWidget);
    expect(find.text('お名前は何ですか。'), findsOneWidget);
    expect(find.text('午前'), findsOneWidget);
    // Nút trạng thái nằm trong thẻ, không còn nút nổi ở góc.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('màn rộng chia hai cột, màn hẹp xếp một cột', (tester) async {
    await _pump(tester, const Size(1400, 1200));
    final heroWide = tester.getTopLeft(find.text('名前'));
    final kanjiWide = tester.getTopLeft(find.text('Phân tích chữ Hán'));
    expect(kanjiWide.dx, greaterThan(heroWide.dx));

    await _pump(tester, const Size(420, 2400));
    final heroNarrow = tester.getTopLeft(find.text('名前'));
    final kanjiNarrow = tester.getTopLeft(find.text('Phân tích chữ Hán'));
    expect(kanjiNarrow.dy, greaterThan(heroNarrow.dy));
  });

  testWidgets('bấm "Chưa học" thì đánh dấu và nút chuyển sang "Đã học"',
      (tester) async {
    final service = await _pump(tester, const Size(1400, 1200));

    await tester.tap(find.text('Chưa học · bấm để đánh dấu'));
    await tester.pumpAndSettle();

    expect(service.marked, ['v1']);
    expect(find.text('Đã học · đang trong lịch ôn tập'), findsOneWidget);
    expect(find.text('Hộp 1/5'), findsOneWidget);
  });
}
