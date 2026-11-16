import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/flashcards/models/flashcard_deck.dart';
import 'package:apphoctiengnnhat/features/flashcards/providers/flashcard_provider.dart';
import 'package:apphoctiengnnhat/features/flashcards/services/flashcard_service.dart';

FlashcardDeck _deck(String id, {String title = 'Bộ thẻ', int cards = 0}) => FlashcardDeck(
      id: id,
      title: title,
      cards: [for (var i = 0; i < cards; i++) FlashcardCard(id: 'c$i', front: 'mặt trước', back: 'mặt sau')],
    );

class _FakeService extends FlashcardService {
  final calls = <String>[];
  Object? failure;
  int totalPages = 1;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<Paged<FlashcardDeck>> listMine({int page = 1, int limit = FlashcardService.pageSize}) =>
      _answer('list $page', Paged(items: [_deck('p$page')], page: page, limit: limit, total: 2, totalPages: totalPages));

  @override
  Future<FlashcardDeck> detail(String id) => _answer('detail $id', _deck(id));

  @override
  Future<FlashcardDeck> createDeck(FlashcardDeckDraft draft) => _answer('create ${draft.title}', _deck('moi', title: draft.title));

  @override
  Future<FlashcardDeck> updateDeck(String id, {required String title, required String description}) =>
      _answer('update $id $title', _deck(id, title: title));

  @override
  Future<void> deleteDeck(String id) => _answer('delete $id', null);

  @override
  Future<FlashcardDeck> addCard(String deckId, FlashcardCardDraft card) => _answer('add $deckId ${card.front}', _deck(deckId, cards: 1));

  @override
  Future<FlashcardDeck> updateCard(String deckId, String cardId, FlashcardCardDraft card) =>
      _answer('edit $deckId $cardId', _deck(deckId, cards: 1));

  @override
  Future<FlashcardDeck> deleteCard(String deckId, String cardId) => _answer('remove $deckId $cardId', _deck(deckId));

  @override
  Future<void> recordStudy(String id) => _answer('study $id', null);
}

const _card = FlashcardCardDraft(front: '学生', back: 'học sinh');

void main() {
  late _FakeService service;
  late FlashcardProvider provider;

  setUp(() {
    service = _FakeService();
    provider = FlashcardProvider(service: service);
  });

  test('tải bộ thẻ của tôi qua ViewState và tải thêm trang sau', () async {
    service.totalPages = 2;
    await provider.loadDecks();
    await provider.loadMore();

    expect(provider.decks.valueOrNull?.map((deck) => deck.id), ['p1', 'p2']);
    expect(provider.hasMore, isFalse);
  });

  test('lỗi tải danh sách hay chi tiết hiện thành ViewFailure đọc được', () async {
    service.failure = ApiException('Mất kết nối');

    await provider.loadDecks();
    await provider.loadDetail('d1');

    expect(provider.decks.errorOrNull, 'Mất kết nối');
    expect(provider.detail.errorOrNull, 'Mất kết nối');
  });

  test('thao tác trên thẻ cập nhật bộ đang mở và tải lại danh sách đã mở', () async {
    await provider.loadDecks();
    await provider.loadDetail('d1');

    expect(await provider.addCard('d1', _card), isNull);
    expect(provider.detailOf('d1').valueOrNull?.cardCount, 1);
    expect(await provider.deleteCard('d1', 'c0'), isNull);
    expect(provider.detailOf('d1').valueOrNull?.cardCount, 0);

    expect(service.calls.where((call) => call.startsWith('list')), hasLength(3));
    expect(provider.isSaving, isFalse);
  });

  test('chi tiết còn sót của bộ mở trước coi như đang tải', () async {
    await provider.loadDetail('d1');

    expect(provider.detailOf('d2').isLoading, isTrue);
  });

  test('ghi thất bại trả câu báo lỗi, không đụng dữ liệu đang hiện', () async {
    await provider.loadDetail('d1');
    service.failure = ApiException('Máy chủ đang bận');

    expect(await provider.updateDeck('d1', title: 'Mới', description: ''), 'Máy chủ đang bận');
    expect(await provider.deleteDeck('d1'), 'Máy chủ đang bận');

    expect(provider.detail.valueOrNull?.title, 'Bộ thẻ');
  });

  test('xoá bộ đang mở thì bỏ chi tiết', () async {
    await provider.loadDetail('d1');

    expect(await provider.deleteDeck('d1'), isNull);

    expect(provider.detail, isA<ViewIdle<FlashcardDeck>>());
  });

  test('thêm vào bộ mới: tạo bộ từ vựng rồi thêm thẻ vào chính bộ đó', () async {
    expect(await provider.addCardToNewDeck('Từ yêu thích', _card), isNull);

    expect(service.calls, ['create Từ yêu thích', 'add moi 学生']);
  });

  test('ghi lượt học hỏng không làm phiền người học', () async {
    service.failure = ApiException('Mất kết nối');

    await provider.recordStudy('d1');

    expect(service.calls, ['study d1']);
  });
}
