import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/notebook/models/notebook.dart';
import 'package:apphoctiengnnhat/features/notebook/providers/notebook_provider.dart';
import 'package:apphoctiengnnhat/features/notebook/services/notebook_service.dart';

Notebook _note(String id, {String title = 'Ghi chú'}) => Notebook(
      id: id,
      title: title,
      content: 'Nội dung',
      type: NoteType.general,
      createdAt: DateTime(2026, 11, 14),
      updatedAt: DateTime(2026, 11, 14),
    );

class _FakeService implements NotebookService {
  final listCalls = <(int, NoteType?, String?)>[];
  final writes = <String>[];
  Object? failure;
  int totalPages = 1;

  Future<T> _maybeFail<T>(T value) async {
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<Paged<Notebook>> list({int page = 1, int limit = NotebookService.pageSize, NoteType? type, String? search}) {
    listCalls.add((page, type, search));
    return _maybeFail(Paged(items: [_note('p$page')], page: page, limit: limit, total: 2, totalPages: totalPages));
  }

  @override
  Future<Notebook> detail(String id) => _maybeFail(_note(id));

  @override
  Future<Notebook> create(NotebookDraft draft) {
    writes.add('create ${draft.title}');
    return _maybeFail(_note('moi', title: draft.title));
  }

  @override
  Future<Notebook> update(String id, NotebookDraft draft) {
    writes.add('update $id ${draft.title}');
    return _maybeFail(_note(id, title: draft.title));
  }

  @override
  Future<void> delete(String id) {
    writes.add('delete $id');
    return _maybeFail(null);
  }
}

const _draft = NotebookDraft(title: 'Mới', content: 'Nội dung');

void main() {
  late _FakeService service;
  late NotebookProvider provider;

  setUp(() {
    service = _FakeService();
    provider = NotebookProvider(service: service);
  });

  test('tải danh sách qua ViewState; lọc và tìm tải lại từ trang đầu với bộ lọc mới', () async {
    await provider.loadNotes();
    expect(provider.notes.valueOrNull?.single.id, 'p1');

    await provider.filterByType(NoteType.kanji);
    await provider.searchNotes('  は ');
    expect(service.listCalls.last, (1, NoteType.kanji, 'は'));
    expect((provider.selectedType, provider.searchQuery), (NoteType.kanji, 'は'));

    await provider.searchNotes('');
    expect(service.listCalls.last, (1, NoteType.kanji, null));
  });

  test('tải thêm nối trang sau vào danh sách đang có', () async {
    service.totalPages = 2;
    await provider.loadNotes();
    expect(provider.hasMore, isTrue);

    await provider.loadMore();
    expect(provider.notes.valueOrNull?.map((note) => note.id), ['p1', 'p2']);
    expect(provider.hasMore, isFalse);
  });

  test('lỗi tải danh sách hay chi tiết hiện thành ViewFailure đọc được', () async {
    service.failure = ApiException('Mất kết nối');

    await provider.loadNotes();
    await provider.loadDetail('n1');

    expect(provider.notes.errorOrNull, 'Mất kết nối');
    expect(provider.detail.errorOrNull, 'Mất kết nối');
  });

  test('chi tiết còn sót của ghi chú mở trước coi như đang tải, không hiện nhầm', () async {
    await provider.loadDetail('n1');

    expect(provider.detailOf('n1').valueOrNull?.id, 'n1');
    expect(provider.detailOf('n2').isLoading, isTrue);
  });

  test('lưu: tạo khi chưa có id, sửa khi có; chi tiết đang mở cập nhật và danh sách tải lại', () async {
    await provider.loadNotes();
    await provider.loadDetail('n1');
    final listedBefore = service.listCalls.length;

    expect(await provider.save(_draft), isNull);
    expect(await provider.save(_draft, id: 'n1'), isNull);

    expect(service.writes, ['create Mới', 'update n1 Mới']);
    expect(provider.detail.valueOrNull?.title, 'Mới');
    expect(service.listCalls.length, listedBefore + 2);
    expect(provider.isSaving, isFalse);
  });

  test('lưu hay xoá thất bại trả câu báo lỗi, không đụng dữ liệu đang hiện', () async {
    await provider.loadNotes();
    await provider.loadDetail('n1');
    service.failure = ApiException('Máy chủ đang bận');

    expect(await provider.save(_draft, id: 'n1'), 'Máy chủ đang bận');
    expect(await provider.delete('n1'), 'Máy chủ đang bận');

    expect(provider.detail.valueOrNull?.id, 'n1');
    expect(provider.notes.valueOrNull?.single.id, 'p1');
  });

  test('xoá ghi chú đang mở thì bỏ chi tiết và tải lại danh sách', () async {
    await provider.loadNotes();
    await provider.loadDetail('n1');

    expect(await provider.delete('n1'), isNull);

    expect(service.writes, ['delete n1']);
    expect(provider.detail, isA<ViewIdle<Notebook>>());
    expect(service.listCalls.length, 2);
  });

  test('chưa mở danh sách thì lưu không kéo danh sách về; đăng xuất xoá sạch', () async {
    expect(await provider.save(_draft), isNull);
    expect(service.listCalls, isEmpty);

    await provider.loadNotes();
    await provider.filterByType(NoteType.grammar);
    provider.clear();

    expect(provider.notes, isA<ViewIdle<List<Notebook>>>());
    expect((provider.selectedType, provider.searchQuery), (null, ''));
  });
}
