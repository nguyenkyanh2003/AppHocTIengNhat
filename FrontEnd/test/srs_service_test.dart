import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apphoctiengnnhat/features/kanji/models/kanji.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_card.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_progress.dart';
import 'package:apphoctiengnnhat/features/srs/services/srs_service.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/services/vocabulary_service.dart';

final progressJson = <String, dynamic>{
  '_id': 'p1', 'item_id': 'v1', 'item_type': 'Vocabulary',
  'box': 2, 'streak': 1, 'next_review': '2026-09-09T00:00:00.123Z',
};

final kanjiProgressJson = <String, dynamic>{...progressJson, 'item_id': 'k1', 'item_type': 'Kanji'};

void main() {
  test('query deduplicates exclusions, omits empty exclusions and only filters when asked', () {
    final query = SrsService.buildDueQuery(excludeCardIds: ['a1', 'b2', 'a1']);
    expect(query, {'limit': '20', 'exclude_card_ids': 'a1,b2'});
    expect(SrsService.buildDueQuery().containsKey('exclude_card_ids'), isFalse);
    expect(SrsService.buildDueQuery(itemType: SrsProgress.itemTypeKanji)['item_type'], 'Kanji');
  });

  test('review sends boolean, the card type and original server timestamp', () {
    final body = SrsService.buildReviewBody(itemId: 'k1', itemType: SrsProgress.itemTypeKanji, isCorrect: false,
        expectedNextReview: DateTime.parse(progressJson['next_review']));
    expect(body['is_correct'], false);
    expect(body['item_type'], 'Kanji');
    expect(body['expected_next_review'], progressJson['next_review']);
    expect(body.containsKey('rating'), isFalse);
  });

  test('missing content stays unavailable and detail parses progress', () {
    final card = SrsCard.fromJson({...progressJson, 'item': null, 'unavailable': true});
    expect(card.unavailable, isTrue);
    expect(card.item, isNull);
    expect(card.progress.nextReview.isUtc, isTrue);
    final detail = Vocabulary.fromJson({'_id': 'v1', 'srs_progress': progressJson});
    expect(detail.srsProgress?.box, 2);
    expect(Vocabulary.fromJson({'_id': 'v2', 'srs_progress': null}).srsProgress, isNull);
  });

  test('each card type parses its own content', () {
    final word = SrsCard.fromJson({...progressJson, 'item': {'_id': 'v1', 'word': '学生'}});
    final kanji = SrsCard.fromJson({
      ...kanjiProgressJson,
      'item': {'_id': 'k1', 'character': '学', 'onyomi': ['ガク'], 'kunyomi': ['まな.ぶ'], 'level': 'N5'},
    });

    expect((word.item! as SrsVocabularyItem).vocabulary.word, '学生');
    final item = kanji.item! as SrsKanjiItem;
    expect(item.kanji.character, '学');
    expect(item.kanji.onyomi, ['ガク']);
    expect(kanji.item!.level, 'N5');
    expect(kanji.progress.itemType, SrsProgress.itemTypeKanji);
  });

  test('kanji detail parses the review progress of the current user', () {
    expect(Kanji.fromJson({'_id': 'k1', 'character': '学', 'srs_progress': kanjiProgressJson}).srsProgress?.box, 2);
    expect(Kanji.fromJson({'_id': 'k1', 'character': '学', 'srs_progress': null}).srsProgress, isNull);
  });

  test('six endpoints decode envelopes without offline cache or old routes', () async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      final service = SrsService();
      final batch = await service.fetchDue(excludeCardIds: ['p3', 'p4']);
      expect(batch.cards.single.progress.itemId, 'v1');
      expect(batch.limit, 20);
      expect(await service.fetchDueCount(), 42);
      expect((await service.fetchStats()).byBox[1], 3);
      await service.review(itemId: 'k1', itemType: 'Kanji', isCorrect: true,
          expectedNextReview: batch.cards.single.progress.nextReview);
      await service.reset(itemId: 'k1', itemType: 'Kanji',
          expectedNextReview: batch.cards.single.progress.nextReview);
      expect(await service.remove(itemId: 'k1', itemType: 'Kanji'), isFalse);
    }, () => MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      final Object data = path.endsWith('/due/count') ? {'total': 42} :
          path.endsWith('/stats') ? {'total_cards': 42, 'due_count': 42, 'by_box': {'1': 3}} :
          path.endsWith('/due') ? [{...progressJson, 'item': {'_id': 'v1', 'word': '学生'}}] :
          request.method == 'DELETE' ? {'deleted': false} : kanjiProgressJson;
      return http.Response(jsonEncode({'data': data, 'limit': 20}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/srs/due', 'GET /api/srs/due/count', 'GET /api/srs/stats',
      'POST /api/srs/review', 'POST /api/srs/items/k1/reset', 'DELETE /api/srs/items/k1',
    ]);
    expect(requests.first.url.queryParameters['exclude_card_ids'], 'p3,p4');
    expect(requests.first.url.queryParameters.containsKey('item_type'), isFalse);
    expect(jsonDecode(requests[3].body)['is_correct'], isTrue);
    expect(jsonDecode(requests[3].body)['item_type'], 'Kanji');
    expect(jsonDecode(requests[4].body)['item_type'], 'Kanji');
    expect(requests[5].url.queryParameters['item_type'], 'Kanji');
  });

  test('fresh vocabulary detail reads progress without mutating', () async {
    await http.runWithClient(() async {
      expect((await VocabularyService().getVocabularyById('v1')).srsProgress?.id, 'p1');
    }, () => MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/vocabulary/v1');
      return http.Response(jsonEncode({'data': {'_id': 'v1', 'srs_progress': progressJson}}), 200);
    }));
  });
}
