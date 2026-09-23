import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_card.dart';
import 'package:apphoctiengnnhat/features/srs/models/srs_progress.dart';
import 'package:apphoctiengnnhat/features/srs/providers/srs_provider.dart';
import 'package:apphoctiengnnhat/features/srs/services/srs_service.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';

final _due = DateTime.utc(2026, 9, 19, 3);

SrsCard _card(String id, {bool unavailable = false, DateTime? nextReview}) => SrsCard(
      progress: SrsProgress(
        id: 'p-$id',
        itemId: id,
        itemType: SrsProgress.itemTypeVocabulary,
        box: 1,
        nextReview: nextReview ?? _due,
        streak: 0,
      ),
      item: unavailable ? null : Vocabulary(id: id, word: 'w$id', hiragana: 'k$id', meaning: 'm$id'),
      unavailable: unavailable,
    );

Map<String, dynamic> _progressJson(String id, DateTime nextReview) => {
      '_id': 'p-$id',
      'item_id': id,
      'item_type': 'Vocabulary',
      'box': 2,
      'streak': 1,
      'next_review': nextReview.toIso8601String(),
    };

/// Service giả: trả các đợt thẻ theo thứ tự, ghi lại mọi lời gọi. Lỗi của lượt
/// ôn kế tiếp đặt qua [reviewErrors].
class _FakeSrsService extends SrsService {
  _FakeSrsService({List<List<SrsCard>> batches = const []}) : _batches = [...batches];

  final List<List<SrsCard>> _batches;
  final List<List<String>> dueExclusions = [];
  final List<int> dueLimits = [];
  final List<(String, bool, DateTime)> reviews = [];
  final List<String> resets = [];
  final List<String> removals = [];
  final List<Object> reviewErrors = [];
  Object? dueError;
  int dueCount = 7;
  Completer<void>? reviewGate;

  @override
  Future<SrsBatch> fetchDue({List<String> excludeItemIds = const [], int limit = SrsService.defaultLimit}) async {
    dueExclusions.add([...excludeItemIds]);
    dueLimits.add(limit);
    if (dueError != null) throw dueError!;
    return SrsBatch(cards: _batches.isEmpty ? const [] : _batches.removeAt(0), limit: limit);
  }

  @override
  Future<int> fetchDueCount() async => dueCount;

  @override
  Future<SrsStats> fetchStats() async =>
      SrsStats(totalCards: 3, dueCount: dueCount, byBox: const {1: 1, 2: 2, 3: 0, 4: 0, 5: 0});

  @override
  Future<SrsProgress> review({
    required String itemId,
    required bool isCorrect,
    required DateTime expectedNextReview,
  }) async {
    reviews.add((itemId, isCorrect, expectedNextReview));
    await reviewGate?.future;
    if (reviewErrors.isNotEmpty) throw reviewErrors.removeAt(0);
    return SrsProgress.fromJson(_progressJson(itemId, _due.add(const Duration(days: 3))));
  }

  @override
  Future<SrsProgress> reset({required String itemId, required DateTime expectedNextReview}) async {
    resets.add(itemId);
    return SrsProgress.fromJson(_progressJson(itemId, _due.add(const Duration(days: 1))));
  }

  @override
  Future<bool> remove({required String itemId}) async {
    removals.add(itemId);
    return true;
  }
}

ApiException _conflict(String code, [Map<String, dynamic>? current]) => BadRequestException(
      'conflict',
      statusCode: 409,
      code: code,
      details: current == null ? null : {'current_progress': current},
    );

Future<(SrsProvider, _FakeSrsService)> _started(List<List<SrsCard>> batches) async {
  final service = _FakeSrsService(batches: batches);
  final provider = SrsProvider(service: service);
  await provider.startSession();
  return (provider, service);
}

void main() {
  test('a session loads the first batch and shows its first card face down', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);

    expect(provider.sessionState, isA<ViewData<List<SrsCard>>>());
    expect(provider.currentCard?.itemId, 'a');
    expect(provider.isRevealed, isFalse);
    expect(service.dueExclusions.single, isEmpty);
  });

  test('an empty first batch ends the session with the summary stats', () async {
    final (provider, _) = await _started([]);

    expect(provider.isFinished, isTrue);
    expect(provider.tally.isEmpty, isTrue);
    expect(provider.statsState.valueOrNull?.totalCards, 3);
    expect(provider.dueCount, 7);
  });

  test('a failed batch load is a failure state that can be retried', () async {
    final service = _FakeSrsService(batches: [
      [_card('a')],
    ])..dueError = NetworkException('mất mạng');
    final provider = SrsProvider(service: service);

    await provider.startSession();
    expect(provider.sessionState.errorOrNull, 'mất mạng');

    service.dueError = null;
    await provider.reloadBatch();
    expect(provider.currentCard?.itemId, 'a');
  });

  test('answering sends the server schedule, counts it, and moves to the next card', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);

    provider.reveal();
    await provider.answer(remembered: false);

    expect(service.reviews.single, ('a', false, _due));
    expect(provider.tally.forgotten, 1);
    expect(provider.currentCard?.itemId, 'b');
    expect(provider.isRevealed, isFalse);
    expect(provider.dueCount, 7, reason: 'badge được làm mới sau mỗi lượt');
  });

  test('a double tap while the answer is in flight sends only one review', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);
    service.reviewGate = Completer<void>();

    final first = provider.answer(remembered: true);
    final second = provider.answer(remembered: true);
    expect(provider.isBusy, isTrue);
    service.reviewGate!.complete();
    await Future.wait([first, second]);

    expect(service.reviews, hasLength(1));
    expect(provider.tally.remembered, 1);
  });

  test('a network error keeps the card and the queue, and retry resends it', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);
    service.reviewErrors.add(NetworkException('Không thể kết nối'));

    await provider.answer(remembered: true);
    expect(provider.currentCard?.itemId, 'a');
    expect(provider.actionError, 'Không thể kết nối');
    expect(provider.tally.answered, 0);

    await provider.retry();
    expect(service.reviews, hasLength(2));
    expect(provider.currentCard?.itemId, 'b');
    expect(provider.actionError, isNull);
  });

  test('a card that is no longer due moves on without counting as an answer', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);
    service.reviewErrors.add(_conflict('SRS_NOT_DUE', _progressJson('a', _due.add(const Duration(days: 3)))));

    await provider.answer(remembered: true);

    expect(provider.currentCard?.itemId, 'b');
    expect(provider.tally.answered, 0);
    expect(provider.consumeNotice(), isNotNull);
    expect(provider.consumeNotice(), isNull, reason: 'thông báo chỉ đọc được một lần');
  });

  test('a changed schedule reloads the card and asks to answer again', () async {
    final newDue = _due.add(const Duration(hours: 1));
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
    ]);
    service.reviewErrors.add(_conflict('SRS_PROGRESS_CHANGED', _progressJson('a', newDue)));
    provider.reveal();

    await provider.answer(remembered: true);
    expect(provider.currentCard?.itemId, 'a');
    expect(provider.currentCard?.progress.nextReview, newDue);
    expect(provider.isRevealed, isFalse);

    await provider.answer(remembered: true);
    expect(service.reviews.last.$3, newDue, reason: 'lần sau gửi lịch mới nhận được');
  });

  test('missing content turns the card unavailable instead of dropping it', () async {
    final (provider, service) = await _started([
      [_card('a')],
    ]);
    service.reviewErrors.add(_conflict('ITEM_UNAVAILABLE'));

    await provider.answer(remembered: true);

    expect(provider.currentCard?.unavailable, isTrue);
  });

  test('skipped and handled cards are excluded when the next batch is fetched', () async {
    final (provider, service) = await _started([
      [_card('a'), _card('b')],
      [_card('c')],
    ]);

    await provider.skip();
    await provider.removeCurrent();

    expect(service.removals, ['b']);
    expect(service.dueExclusions.last, ['a', 'b']);
    expect(provider.currentCard?.itemId, 'c');
    expect(provider.tally.skipped, 1);
    expect(provider.tally.removed, 1);
  });

  test('when every remaining card was skipped the session ends even if cards are still due', () async {
    final (provider, service) = await _started([
      [_card('a')],
    ]);

    await provider.skip();

    expect(provider.isFinished, isTrue);
    expect(provider.dueCount, 7);
    expect(service.dueExclusions.last, ['a']);
  });

  test('reset counts separately and a new session forgets the exclusions', () async {
    final (provider, service) = await _started([
      [_card('a')],
      [],
      [_card('a')],
    ]);

    await provider.resetCurrent();
    expect(service.resets, ['a']);
    expect(provider.tally.reset, 1);

    await provider.startSession();
    expect(service.dueExclusions.last, isEmpty);
    expect(provider.tally.isEmpty, isTrue);
  });

  test('the batch size shrinks to stay within the session limit', () async {
    final cards = List.generate(SrsProvider.sessionLimit - 5, (i) => _card('c$i'));
    final (provider, service) = await _started([cards, []]);

    for (var i = 0; i < cards.length; i++) {
      await provider.skip();
    }

    expect(service.dueLimits.last, 5);
  });
}
