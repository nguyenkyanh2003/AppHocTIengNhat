import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_card.dart';
import 'package:apphoctiengnnhat/features/srs/services/srs_service.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/services/vocabulary_service.dart';

final progressJson = <String, dynamic>{
  '_id': 'p1', 'item_id': 'v1', 'item_type': 'Vocabulary',
  'box': 2, 'streak': 1, 'next_review': '2026-09-09T00:00:00.123Z',
};

void main() {
  test('query deduplicates exclusions and omits empty exclusions', () {
    final query = SrsService.buildDueQuery(excludeItemIds: ['a1', 'b2', 'a1']);
    expect(query, {'item_type': 'Vocabulary', 'limit': '20', 'exclude_item_ids': 'a1,b2'});
    expect(SrsService.buildDueQuery().containsKey('exclude_item_ids'), isFalse);
  });

  test('review sends boolean and original server timestamp', () {
    final body = SrsService.buildReviewBody(itemId: 'v1', isCorrect: false,
        expectedNextReview: DateTime.parse(progressJson['next_review']));
    expect(body['is_correct'], false);
    expect(body['expected_next_review'], progressJson['next_review']);
    expect(body.containsKey('rating'), isFalse);
  });

  test('missing content stays unavailable and detail parses progress', () {
    final card = SrsCard.fromJson({...progressJson, 'item': null, 'unavailable': true});
    expect(card.unavailable, isTrue);
    expect(card.progress.nextReview.isUtc, isTrue);
    final detail = Vocabulary.fromJson({'_id': 'v1', 'srs_progress': progressJson});
    expect(detail.srsProgress?.box, 2);
    expect(Vocabulary.fromJson({'_id': 'v2', 'srs_progress': null}).srsProgress, isNull);
  });

  test('six endpoints decode envelopes without offline cache or old routes', () async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      final service = SrsService();
      final batch = await service.fetchDue(excludeItemIds: ['v3', 'v4']);
      expect(batch.cards.single.progress.itemId, 'v1');
      expect(batch.limit, 20);
      expect(await service.fetchDueCount(), 42);
      expect((await service.fetchStats()).byBox[1], 3);
      await service.review(itemId: 'v1', isCorrect: true,
          expectedNextReview: batch.cards.single.progress.nextReview);
      await service.reset(itemId: 'v1', expectedNextReview: batch.cards.single.progress.nextReview);
      expect(await service.remove(itemId: 'v1'), isFalse);
    }, () => MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      final Object data = path.endsWith('/due/count') ? {'total': 42} :
          path.endsWith('/stats') ? {'total_cards': 42, 'due_count': 42, 'by_box': {'1': 3}} :
          path.endsWith('/due') ? [{...progressJson, 'item': {'_id': 'v1', 'word': '学生'}}] :
          request.method == 'DELETE' ? {'deleted': false} : progressJson;
      return http.Response(jsonEncode({'data': data, 'limit': 20}), 200);
    }));
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/srs/due', 'GET /api/srs/due/count', 'GET /api/srs/stats',
      'POST /api/srs/review', 'POST /api/srs/items/v1/reset', 'DELETE /api/srs/items/v1',
    ]);
    expect(requests.first.url.queryParameters['exclude_item_ids'], 'v3,v4');
    expect(jsonDecode(requests[3].body)['is_correct'], isTrue);
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
