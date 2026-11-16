import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/flashcards/models/flashcard_deck.dart';
import 'package:apphoctiengnnhat/features/flashcards/services/flashcard_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _deck = {
  '_id': 'd1',
  'title': 'N5',
  'description': 'Gia đình',
  'user': 'u1',
  'cards': [
    {'_id': 'c1', 'front': '学生', 'back': 'học sinh', 'front_subtext': 'がくせい'},
  ],
  'is_public': false,
  'category': 'custom',
  'level': 'N5',
  'total_cards': 1,
  'study_count': 3,
};

void main() {
  test('danh sách bộ thẻ của tôi là một trang theo contract phân trang', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => FlashcardService().listMine(page: 2),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_deck], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(url.path, '/api/flashcard/decks');
    expect(url.queryParameters, {'page': '2', 'limit': '20'});
    final deck = page.items.single;
    expect((deck.title, deck.cardCount, deck.studyCount, deck.level), ('N5', 1, 3, 'N5'));
    expect(deck.cards.single.frontSubtext, 'がくせい');
  });

  test('tạo, sửa bộ và thêm, sửa, xoá thẻ gửi đúng route và body, đọc lại bộ trong `data`', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final service = FlashcardService();

    await http.runWithClient(
      () async {
        await service.createDeck(const FlashcardDeckDraft(title: 'N5', isPublic: true, category: 'vocabulary'));
        await service.updateDeck('d1', title: 'N4', description: '');
        await service.addCard('d1', const FlashcardCardDraft(front: '学生', back: 'học sinh'));
        await service.updateCard('d1', 'c1', const FlashcardCardDraft(front: '学生', back: 'sinh viên', backSubtext: 'đại học'));
        expect((await service.deleteCard('d1', 'c1')).id, 'd1');
        await service.deleteDeck('d1');
        await service.recordStudy('d1');
      },
      () => MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        bodies.add(request.body.isEmpty ? null : jsonDecode(request.body));
        return request.url.path.endsWith('/study')
            ? _json({'data': {'study_count': 4}})
            : _json({'data': request.method == 'DELETE' && request.url.pathSegments.length == 4 ? {'deleted': true} : _deck});
      }),
    );

    expect(requests, [
      'POST /api/flashcard/decks',
      'PUT /api/flashcard/decks/d1',
      'POST /api/flashcard/decks/d1/cards',
      'PUT /api/flashcard/decks/d1/cards/c1',
      'DELETE /api/flashcard/decks/d1/cards/c1',
      'DELETE /api/flashcard/decks/d1',
      'POST /api/flashcard/decks/d1/study',
    ]);
    expect(bodies[0], {'title': 'N5', 'description': '', 'is_public': true, 'category': 'vocabulary'});
    expect(bodies[1], {'title': 'N4', 'description': ''});
    expect(bodies[2], {'front': '学生', 'back': 'học sinh', 'front_subtext': null, 'back_subtext': null});
    expect(bodies[3], {'front': '学生', 'back': 'sinh viên', 'front_subtext': null, 'back_subtext': 'đại học'});
  });

  test('response thiếu `data` là lỗi rõ ràng', () async {
    await expectLater(
      http.runWithClient(() => FlashcardService().detail('d1'), () => MockClient((_) async => _json(_deck))),
      throwsA(isA<ServerException>()),
    );
  });
}
