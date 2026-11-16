import '../../../core/network/api_envelope.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../../lessons/models/lesson.dart';
import '../models/admin_content_type.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Kết quả nhập CSV: số dòng đã tạo, và lỗi của dòng đầu tiên hỏng (nếu có).
typedef ContentImport = ({int imported, String? error});

/// Nội dung học của một loại đang chọn, dạng document gốc, cùng các thao tác
/// thêm/sửa/xoá và nhập từ CSV hoặc Excel.
class AdminContentProvider extends AdminScreenProvider {
  AdminContentProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;
  late final _items = PagedList<JsonObject>(onChanged: notify);
  AdminContentType _type = AdminContentType.vocabulary;
  bool _importing = false;

  AdminContentType get type => _type;
  ViewState<List<JsonObject>> get items => _items.state;
  bool get hasMore => _items.hasMore;
  bool get isLoadingMore => _items.isLoadingMore;
  String? get loadMoreError => _items.loadMoreError;
  bool get isRefreshing => _items.isRefreshing;

  /// Đang nhập tệp: màn hiện thanh tiến trình và khoá nút nhập.
  bool get isImporting => _importing;

  Future<void> load({bool keepCurrent = false}) {
    final type = _type;
    return _items.load((page) => _service.content(type, page: page), keepCurrent: keepCurrent);
  }

  Future<void> loadMore() => _items.loadMore();

  /// Đổi loại nội dung: danh sách loại cũ không hiện lẫn trong lúc chờ.
  Future<void> selectType(AdminContentType type) {
    _type = type;
    return load();
  }

  /// Tạo mới ([id] `null`) hoặc sửa một document.
  Future<String?> save(JsonObject document, {String? id}) {
    final type = _type;
    return write(
      () => id == null ? _service.createContent(type, document) : _service.updateContent(type, id, document),
      refresh: _refresh,
    );
  }

  Future<String?> delete(String id) {
    final type = _type;
    return write(() => _service.deleteContent(type, id), refresh: _refresh);
  }

  /// Tạo lần lượt từng dòng CSV; dừng ở dòng hỏng đầu tiên và báo số dòng
  /// trong tệp (dòng 1 là tiêu đề) để admin sửa đúng chỗ.
  Future<ContentImport> importRows(List<JsonObject> rows) => _whileImporting(() async {
        final type = _type;
        var imported = 0;
        String? error;
        for (final row in rows) {
          final result = await ViewState.guard(() => _service.createContent(type, row));
          if (result.errorOrNull case final message?) {
            error = 'Dòng ${imported + 2}: $message';
            break;
          }
          imported++;
        }
        if (imported > 0 && !disposed) await _refresh();
        return (imported: imported, error: error);
      });

  /// Import tệp Excel của loại đang chọn.
  ///
  /// [lesson] và [level] chỉ dùng cho từ vựng: backend áp hai giá trị này cho
  /// mọi dòng của tệp. Kanji đọc bài học và cấp độ theo từng dòng.
  Future<String?> importExcel(List<int> bytes, String fileName, {String? lesson, String? level}) async {
    switch (_type) {
      case AdminContentType.vocabulary:
        if (lesson == null || lesson.isEmpty || level == null || level.isEmpty) {
          return 'Cần chọn bài học và cấp độ trước khi import.';
        }
        return _whileImporting(() => write(
              () => _service.importVocabularyExcel(bytes, fileName, lesson: lesson, level: level),
              refresh: _refresh,
            ));
      case AdminContentType.kanji:
        return _whileImporting(() => write(() => _service.importKanjiExcel(bytes, fileName), refresh: _refresh));
      case AdminContentType.grammar || AdminContentType.lessons:
        return 'Excel chỉ hỗ trợ từ vựng và Kanji.';
    }
  }

  /// Bài học để gán cho tệp Excel từ vựng.
  Future<ViewState<List<Lesson>>> lessonOptions() => ViewState.guard(_service.lessonOptions);

  Future<void> _refresh() => _items.reload(keepCurrent: true);

  Future<T> _whileImporting<T>(Future<T> Function() task) async {
    _importing = true;
    notify();
    try {
      return await task();
    } finally {
      _importing = false;
      notify();
    }
  }
}
