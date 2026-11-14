import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/kanji/models/kanji.dart';
import 'package:apphoctiengnnhat/features/kanji/providers/kanji_detail_provider.dart';
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

/// Service giả: một chữ trong kho, ghi lại lệnh thêm/gỡ, lỗi đặt trước được.
class _FakeKanjiService extends KanjiService {
  _FakeKanjiService({this.inReview = false});

  bool inReview;
  final List<String> calls = [];
  Object? nextError;

  void _maybeThrow() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  @override
  Future<Kanji> detail(String id) async {
    calls.add('get $id');
    _maybeThrow();
    return Kanji(id: id, character: '学', srsProgress: inReview ? _progress : null);
  }

  @override
  Future<SrsProgress> addToReview(String id) async {
    calls.add('add $id');
    _maybeThrow();
    inReview = true;
    return _progress;
  }

  @override
  Future<void> removeFromReview(String id) async {
    calls.add('remove $id');
    _maybeThrow();
    inReview = false;
  }
}

void main() {
  test('tải chi tiết rồi biết chữ đã có trong lịch ôn hay chưa', () async {
    final provider = KanjiDetailProvider(service: _FakeKanjiService(inReview: true));

    await provider.load('k1');

    expect(provider.detailState, isA<ViewData<Kanji>>());
    expect(provider.kanji?.isInReview, isTrue);
  });

  test('lỗi tải là trạng thái lỗi có câu thông báo, không phải exception thô', () async {
    final service = _FakeKanjiService()..nextError = NetworkException('mất mạng');
    final provider = KanjiDetailProvider(service: service);

    await provider.load('k1');

    expect(provider.detailState.errorOrNull, 'mất mạng');
  });

  test('thêm vào ôn tập cập nhật ngay trạng thái "đã thêm"', () async {
    final service = _FakeKanjiService();
    final provider = KanjiDetailProvider(service: service);
    await provider.load('k1');

    final error = await provider.toggleReview();

    expect(error, isNull);
    expect(service.calls, ['get k1', 'add k1']);
    expect(provider.kanji?.srsProgress?.box, 1);
    expect(provider.isSaving, isFalse);
  });

  test('bấm lần nữa thì gỡ khỏi lịch ôn', () async {
    final service = _FakeKanjiService(inReview: true);
    final provider = KanjiDetailProvider(service: service);
    await provider.load('k1');

    expect(await provider.toggleReview(), isNull);

    expect(service.calls.last, 'remove k1');
    expect(provider.kanji?.isInReview, isFalse);
  });

  test('thêm thất bại thì giữ nguyên trạng thái và trả câu lỗi để màn hình báo', () async {
    final service = _FakeKanjiService();
    final provider = KanjiDetailProvider(service: service);
    await provider.load('k1');
    service.nextError = NetworkException('Không thể kết nối');

    final error = await provider.toggleReview();

    expect(error, 'Không thể kết nối');
    expect(provider.kanji?.isInReview, isFalse);
    expect(provider.isSaving, isFalse);
  });

  test('service gọi đúng route thêm/gỡ và đọc chi tiết không qua cache', () async {
    final requests = <String>[];
    await http.runWithClient(() async {
      final service = KanjiService();
      expect((await service.detail('k1')).srsProgress, isNull);
      expect((await service.addToReview('k1')).itemType, 'Kanji');
      await service.removeFromReview('k1');
    }, () => MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      final Object data = request.method == 'GET'
          ? {'_id': 'k1', 'character': '学', 'srs_progress': null}
          : request.method == 'POST'
              ? {
                  '_id': 'p1',
                  'item_id': 'k1',
                  'item_type': 'Kanji',
                  'box': 1,
                  'streak': 0,
                  'next_review': '2026-11-05T03:00:00.000Z',
                }
              : {'deleted': true};
      return http.Response(jsonEncode({'data': data}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));

    expect(requests, [
      'GET /api/kanji/k1',
      'POST /api/kanji/k1/mark-learned',
      'DELETE /api/kanji/k1/mark-learned',
    ]);
  });
}
