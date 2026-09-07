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

  test('tải danh sách thành công thì có dữ liệu và thông tin phân trang', () async {
    final provider = VocabularyProvider(
      service: _FakeVocabularyService(
        pages: {1: _page([_word('1'), _word('2')], 1, 3)},
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
        pages: {1: _page([_word('1')], 1, 1)},
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
        pages: {1: _page([_word('1')], 1, 1)},
      ),
    );

    await provider.searchVocabularies('   ');

    expect(provider.vocabularies, hasLength(1));
    expect(provider.searchQuery, isEmpty);
  });

  test('lọc theo trạng thái học được truyền xuống service', () async {
    final service = _FakeVocabularyService(
      pages: {1: _page([_word('1')], 1, 1)},
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
        pages: {1: _page([_word('1')], 1, 2)},
      ),
    );

    await provider.loadVocabularies(refresh: true);
    await provider.filterByLevel('N4');
    provider.clear();

    expect(provider.listState, isA<ViewIdle<List<Vocabulary>>>());
    expect(provider.selectedLevel, isNull);
    expect(provider.totalItems, 0);
  });
}
