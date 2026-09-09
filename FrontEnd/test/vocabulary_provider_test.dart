import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:apphoctiengnnhat/features/vocabulary/services/vocabulary_service.dart';

Vocabulary _word(String id) => Vocabulary(
      id: id,
      word: 'word-$id',
      hiragana: 'kana-$id',
      meaning: 'nghĩa $id',
      level: 'N5',
    );

/// Service giả: không chạm mạng, ghi lại tham số được truyền xuống.
class _FakeVocabularyService extends VocabularyService {
  _FakeVocabularyService({this.pages = const {}, this.searchResult = const []});

  final Map<int, VocabularyPage> pages;
  final List<Vocabulary> searchResult;

  Object? error;
  String? lastStudyStatus;
  final List<String> markedLearned = [];
  final List<String> unmarked = [];

  @override
  Future<VocabularyPage> getVocabularies({
    int page = 1,
    int limit = 20,
    String? level,
    String? studyStatus,
    String? sortBy,
  }) async {
    if (error != null) throw error!;
    lastStudyStatus = studyStatus;
    return pages[page] ??
        const VocabularyPage(
          items: [],
          page: 1,
          limit: 20,
          total: 0,
          totalPages: 0,
        );
  }

  @override
  Future<List<Vocabulary>> searchVocabularies({
    required String keyword,
    String? level,
  }) async {
    if (error != null) throw error!;
    return searchResult;
  }

  @override
  Future<void> markAsLearned(String vocabularyId) async {
    markedLearned.add(vocabularyId);
  }

  @override
  Future<void> unmarkAsLearned(String vocabularyId) async {
    unmarked.add(vocabularyId);
  }
}

/// Service giả điều khiển được **thứ tự** phản hồi.
///
/// Mỗi lời gọi trả về một [Completer] riêng, nên test quyết định được phản hồi
/// nào về trước — điều kiện bắt buộc để tái hiện cảnh phản hồi cũ về sau phản
/// hồi mới.
class _DeferredVocabularyService extends VocabularyService {
  final List<Completer<VocabularyPage>> pageRequests = [];
  final List<Completer<List<Vocabulary>>> searchRequests = [];
  final List<Completer<Vocabulary>> detailRequests = [];
  final List<int> requestedPages = [];
  final List<String?> requestedLevels = [];

  @override
  Future<Vocabulary> getVocabularyById(String id) {
    final completer = Completer<Vocabulary>();
    detailRequests.add(completer);
    return completer.future;
  }

  @override
  Future<VocabularyPage> getVocabularies({
    int page = 1,
    int limit = 20,
    String? level,
    String? studyStatus,
    String? sortBy,
  }) {
    requestedPages.add(page);
    requestedLevels.add(level);
    final completer = Completer<VocabularyPage>();
    pageRequests.add(completer);
    return completer.future;
  }

  @override
  Future<List<Vocabulary>> searchVocabularies({
    required String keyword,
    String? level,
  }) {
    final completer = Completer<List<Vocabulary>>();
    searchRequests.add(completer);
    return completer.future;
  }
}

VocabularyPage _page(List<Vocabulary> items, int page, int totalPages) =>
    VocabularyPage(
      items: items,
      page: page,
      limit: 20,
      total: totalPages * 20,
      totalPages: totalPages,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trạng thái ban đầu là idle, chưa gọi service', () {
    final provider = VocabularyProvider(service: _FakeVocabularyService());

    expect(provider.listState, isA<ViewIdle<List<Vocabulary>>>());
    expect(provider.vocabularies, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('tải danh sách thành công thì có dữ liệu và thông tin phân trang',
      () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {
          1: _page([_word('1'), _word('2')], 1, 3)
        },
      ),
    );

    await provider.loadVocabularies(refresh: true);

    expect(provider.listState, isA<ViewData<List<Vocabulary>>>());
    expect(provider.vocabularies, hasLength(2));
    expect(provider.currentPage, 1);
    expect(provider.totalPages, 3);
    expect(provider.hasNextPage, isTrue);
    expect(provider.error, isNull);
  });

  test('loadMore nối thêm trang sau, không thay thế danh sách cũ', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {
          1: _page([_word('1')], 1, 2),
          2: _page([_word('2')], 2, 2),
        },
      ),
    );

    await provider.loadVocabularies(refresh: true);
    await provider.loadMore();

    expect(provider.vocabularies.map((item) => item.id), ['1', '2']);
    expect(provider.currentPage, 2);
    expect(provider.hasNextPage, isFalse);
  });

  test('loadMore không làm gì khi đã ở trang cuối', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {
          1: _page([_word('1')], 1, 1)
        },
      ),
    );

    await provider.loadVocabularies(refresh: true);
    await provider.loadMore();

    expect(provider.vocabularies, hasLength(1));
  });

  test('lỗi API được dịch sang thông báo cho người dùng', () async {
    final service = _FakeVocabularyService()
      ..error = NotFoundException('Không tìm thấy từ vựng.');
    final provider = VocabularyProvider(service: service);

    await provider.loadVocabularies(refresh: true);

    expect(provider.listState, isA<ViewFailure<List<Vocabulary>>>());
    expect(provider.error, 'Không tìm thấy từ vựng.');
    expect(provider.vocabularies, isEmpty);
  });

  test('lỗi lạ không lộ chi tiết kỹ thuật ra màn hình', () async {
    final service = _FakeVocabularyService()..error = StateError('boom');
    final provider = VocabularyProvider(service: service);

    await provider.loadVocabularies(refresh: true);

    expect(provider.error, 'Đã có lỗi xảy ra. Vui lòng thử lại.');
  });

  test('tìm kiếm không có kết quả là danh sách rỗng, không phải lỗi', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(searchResult: const []),
    );

    await provider.searchVocabularies('không tồn tại');

    expect(provider.listState, isA<ViewData<List<Vocabulary>>>());
    expect(provider.vocabularies, isEmpty);
    expect(provider.error, isNull);
    expect(provider.totalItems, 0);
  });

  test('tìm kiếm rỗng thì quay lại danh sách đầy đủ', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {
          1: _page([_word('1')], 1, 1)
        },
      ),
    );

    await provider.searchVocabularies('   ');

    expect(provider.vocabularies, hasLength(1));
    expect(provider.searchQuery, isEmpty);
  });

  test('lọc theo trạng thái học được truyền xuống service', () async {
    final service = _FakeVocabularyService(
      pages: {
        1: _page([_word('1')], 1, 1)
      },
    );
    final provider = VocabularyProvider(service: service);

    await provider.filterByStudyStatus('learned');

    expect(service.lastStudyStatus, 'learned');
    expect(provider.studyStatus, 'learned');
  });

  test('đánh dấu và bỏ đánh dấu đã học gọi đúng service', () async {
    final service = _FakeVocabularyService();
    final provider = VocabularyProvider(service: service);

    await provider.markAsLearned('v1');
    await provider.unmarkAsLearned('v1');

    expect(service.markedLearned, ['v1']);
    expect(service.unmarked, ['v1']);
  });

  test('clear đưa provider về trạng thái ban đầu', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {
          1: _page([_word('1')], 1, 2)
        },
      ),
    );

    await provider.loadVocabularies(refresh: true);
    await provider.filterByLevel('N4');
    provider.clear();

    expect(provider.listState, isA<ViewIdle<List<Vocabulary>>>());
    expect(provider.selectedLevel, isNull);
    expect(provider.totalItems, 0);
  });

  group('phản hồi lỗi thời', () {
    test('kết quả N5 về sau không ghi đè danh sách lẫn phân trang của N4',
        () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final n5 = provider.filterByLevel('N5');
      final n4 = provider.filterByLevel('N4');

      expect(service.requestedLevels, ['N5', 'N4']);

      // N4 (yêu cầu mới) về trước, N5 (yêu cầu đã bị bỏ) về sau.
      service.pageRequests[1].complete(_page([_word('n4')], 1, 1));
      await n4;
      service.pageRequests[0].complete(_page([_word('n5')], 3, 9));
      await n5;

      expect(provider.vocabularies.map((item) => item.id), ['n4']);
      expect(provider.currentPage, 1);
      expect(provider.totalPages, 1);
      expect(provider.totalItems, 20);
      expect(provider.hasNextPage, isFalse);
    });

    test('trang 2 cũ về sau khi đã tìm kiếm mới thì không nối vào kết quả',
        () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final first = provider.loadVocabularies(refresh: true);
      service.pageRequests[0].complete(_page([_word('1')], 1, 5));
      await first;

      final more = provider.loadMore();
      final search = provider.searchVocabularies('あ');

      service.searchRequests[0].complete([_word('tim-kiem')]);
      await search;
      service.pageRequests[1].complete(_page([_word('2')], 2, 5));
      await more;

      expect(provider.vocabularies.map((item) => item.id), ['tim-kiem']);
      expect(provider.totalPages, 1);
      expect(provider.currentPage, 1);
      expect(provider.isLoadingMore, isFalse);
    });

    test('lỗi của yêu cầu cũ không xoá danh sách của yêu cầu mới', () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final stale = provider.filterByLevel('N5');
      final fresh = provider.filterByLevel('N4');

      service.pageRequests[1].complete(_page([_word('n4')], 1, 1));
      await fresh;
      service.pageRequests[0].completeError(ServerException('Lỗi máy chủ'));
      await stale;

      expect(provider.listState, isA<ViewData<List<Vocabulary>>>());
      expect(provider.error, isNull);
      expect(provider.vocabularies.map((item) => item.id), ['n4']);
    });

    test('mở chi tiết không huỷ yêu cầu của danh sách', () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final list = provider.loadVocabularies(refresh: true);
      final detail = provider.loadVocabularyDetail('1');

      service.pageRequests[0].complete(_page([_word('1')], 1, 2));
      await list;

      // Danh sách vẫn nhận được kết quả dù chi tiết đang chạy song song.
      expect(provider.vocabularies, hasLength(1));
      expect(provider.totalPages, 2);

      service.detailRequests[0].complete(_word('1'));
      await detail;

      expect(provider.selectedVocabulary?.id, '1');
      expect(provider.vocabularies, hasLength(1));
    });

    test('clear khi còn request đang chạy thì phản hồi về sau bị bỏ qua',
        () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final pending = provider.loadVocabularies(refresh: true);
      provider.clear();

      service.pageRequests[0].complete(_page([_word('1')], 1, 4));
      await pending;

      expect(provider.listState, isA<ViewIdle<List<Vocabulary>>>());
      expect(provider.totalPages, 1);
      expect(provider.totalItems, 0);
    });
  });

  group('tải thêm', () {
    test('gọi loadMore liên tiếp chỉ gửi một yêu cầu trang 2', () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final first = provider.loadVocabularies(refresh: true);
      service.pageRequests[0].complete(_page([_word('1')], 1, 3));
      await first;

      final a = provider.loadMore();
      final b = provider.loadMore();
      final c = provider.loadMore();

      expect(service.requestedPages, [1, 2]);
      expect(provider.isLoadingMore, isTrue);

      service.pageRequests[1].complete(_page([_word('2')], 2, 3));
      await Future.wait([a, b, c]);

      expect(provider.vocabularies.map((item) => item.id), ['1', '2']);
      expect(provider.isLoadingMore, isFalse);
    });

    test('danh sách vẫn hiển thị trong lúc tải thêm', () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final first = provider.loadVocabularies(refresh: true);
      service.pageRequests[0].complete(_page([_word('1')], 1, 3));
      await first;

      final more = provider.loadMore();

      // Không được chuyển sang loading: làm vậy là tháo ListView và người dùng
      // mất vị trí cuộn.
      expect(provider.listState, isA<ViewData<List<Vocabulary>>>());
      expect(provider.vocabularies, hasLength(1));
      expect(provider.isLoadingMore, isTrue);

      service.pageRequests[1].complete(_page([_word('2')], 2, 3));
      await more;
    });

    test('tải thêm lỗi giữ nguyên danh sách và trang, retry đúng trang lỗi',
        () async {
      final service = _DeferredVocabularyService();
      final provider = VocabularyProvider(service: service);

      final first = provider.loadVocabularies(refresh: true);
      service.pageRequests[0].complete(_page([_word('1')], 1, 3));
      await first;

      final failing = provider.loadMore();
      service.pageRequests[1].completeError(ServerException('Mất kết nối'));
      await failing;

      expect(provider.vocabularies.map((item) => item.id), ['1']);
      expect(provider.currentPage, 1);
      expect(provider.listState, isA<ViewData<List<Vocabulary>>>());
      expect(provider.loadMoreError, 'Mất kết nối');
      expect(provider.isLoadingMore, isFalse);

      final retry = provider.loadMore();
      expect(service.requestedPages, [1, 2, 2]);
      expect(provider.loadMoreError, isNull);

      service.pageRequests[2].complete(_page([_word('2')], 2, 3));
      await retry;

      expect(provider.vocabularies.map((item) => item.id), ['1', '2']);
      expect(provider.currentPage, 2);
    });
  });
}
