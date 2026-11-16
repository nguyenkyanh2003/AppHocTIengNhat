import 'package:flutter/foundation.dart';

import '../../../core/state/detail_state.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/notebook.dart';
import '../services/notebook_service.dart';

/// Danh sách sổ tay (lọc theo loại, tìm theo từ khoá, tải thêm khi cuộn), ghi
/// chú đang mở và các thao tác tạo/sửa/xoá.
///
/// Sau mỗi lần ghi thành công, danh sách đã mở được tải lại để khớp thứ tự và
/// tổng số do server tính.
class NotebookProvider extends ChangeNotifier {
  NotebookProvider({NotebookService? service}) : _service = service ?? NotebookService();

  final NotebookService _service;
  late final _notes = PagedList<Notebook>(onChanged: _notify);
  late final _detail = DetailState<Notebook>(idOf: (note) => note.id, onChanged: _notify);
  NoteType? _type;
  String _search = '';
  bool _saving = false;
  bool _disposed = false;

  ViewState<List<Notebook>> get notes => _notes.state;
  bool get hasMore => _notes.hasMore;
  bool get isLoadingMore => _notes.isLoadingMore;
  String? get loadMoreError => _notes.loadMoreError;
  ViewState<Notebook> get detail => _detail.state;

  /// Chi tiết của đúng ghi chú [id] (xem [DetailState.of]).
  ViewState<Notebook> detailOf(String id) => _detail.of(id);

  NoteType? get selectedType => _type;
  String get searchQuery => _search;
  bool get isSaving => _saving;

  Future<void> loadNotes() {
    final type = _type;
    final search = _search.isEmpty ? null : _search;
    return _notes.load((page) => _service.list(page: page, type: type, search: search));
  }

  Future<void> loadMore() => _notes.loadMore();

  Future<void> searchNotes(String keyword) {
    _search = keyword.trim();
    return loadNotes();
  }

  Future<void> filterByType(NoteType? type) {
    _type = type;
    return loadNotes();
  }

  Future<void> loadDetail(String id) => _detail.load(id, () => _service.detail(id));

  /// Tạo mới khi không có [id], ngược lại sửa ghi chú [id]. Trả `null` khi đã
  /// lưu, hoặc câu báo lỗi để form hiện.
  Future<String?> save(NotebookDraft draft, {String? id}) async {
    if (_saving) return 'Ghi chú đang được lưu.';
    _saving = true;
    _notify();

    final result = await ViewState.guard(() => id == null ? _service.create(draft) : _service.update(id, draft));
    _saving = false;
    if (result case ViewData(:final value)) _detail.replace(value);
    _notify();
    if (result.hasData) _reloadOpenList();
    return result.errorOrNull;
  }

  /// Trả `null` khi đã xoá, hoặc câu báo lỗi để màn hiện.
  Future<String?> delete(String id) async {
    final result = await ViewState.guard(() => _service.delete(id));
    if (!result.hasData) return result.errorOrNull;
    _detail.remove(id);
    _reloadOpenList();
    return null;
  }

  /// Về trạng thái chưa tải (đăng xuất).
  void clear() {
    _notes.clear();
    _detail.clear();
    _type = null;
    _search = '';
    _notify();
  }

  void _reloadOpenList() {
    if (_notes.state is! ViewIdle) _notes.reload();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
