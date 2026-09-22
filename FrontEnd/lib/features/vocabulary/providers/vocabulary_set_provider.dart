import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_set.dart';
import '../services/vocabulary_service.dart';

/// State của phần "Bộ từ vựng": danh sách bộ theo cấp và một bộ đang mở.
///
/// Tách khỏi [VocabularyProvider] vì hai bên không chung state nào: bên kia
/// là danh sách tra cứu có phân trang và bộ lọc, bên này là các bộ chia sẵn.
class VocabularySetProvider extends ChangeNotifier {
  VocabularySetProvider({VocabularyService? service})
      : _service = service ?? VocabularyService();

  final VocabularyService _service;

  static const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  String _level = levels.first;
  ViewState<List<VocabularySet>> _sets = const ViewState.idle();
  ViewState<VocabularySetDetail> _detail = const ViewState.idle();
  bool _isMarking = false;
  bool _disposed = false;

  /// Chống phản hồi đến muộn: đổi cấp nhanh N5 → N3 thì kết quả N5 về sau
  /// không được ghi đè danh sách N3.
  int _setsGeneration = 0;
  int _detailGeneration = 0;

  String get level => _level;
  ViewState<List<VocabularySet>> get setsState => _sets;
  ViewState<VocabularySetDetail> get detailState => _detail;
  bool get isMarking => _isMarking;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Chọn cấp mặc định theo trình độ người dùng, chỉ khi chưa tải lần nào —
  /// không ghi đè cấp người dùng đã tự chọn.
  void useDefaultLevel(String? userLevel) {
    if (_sets is! ViewIdle || !levels.contains(userLevel)) return;
    _level = userLevel!;
  }

  Future<void> selectLevel(String level) async {
    if (level == _level && _sets.hasData) return;
    _level = level;
    await loadSets();
  }

  /// [silent]: làm mới tiến độ khi quay về từ một bộ — giữ danh sách đang
  /// hiện (và vị trí cuộn) thay vì thay bằng vòng xoay.
  Future<void> loadSets({bool silent = false}) async {
    final generation = ++_setsGeneration;
    final level = _level;
    if (!(silent && _sets.hasData)) {
      _sets = const ViewState.loading();
      _notify();
    }

    final result = await ViewState.guard(() => _service.getSets(level));
    if (generation != _setsGeneration) return;
    _sets = result;
    _notify();
  }

  Future<void> loadSet(String setId) async {
    final generation = ++_detailGeneration;
    // Mở lại đúng bộ đang xem (sau khi học xong) thì giữ nội dung cũ trên màn
    // trong lúc tải, không nháy về vòng xoay.
    if (_detail.valueOrNull?.set.id != setId) {
      _detail = const ViewState.loading();
      _notify();
    }

    final result = await ViewState.guard(() => _service.getSet(setId));
    if (generation != _detailGeneration) return;
    _detail = result;
    _notify();
  }

  /// Đánh dấu mọi từ chưa học trong bộ đang mở là đã học, để chúng vào lịch
  /// ôn tập. Trả về số từ đã đánh dấu.
  Future<int> markCurrentSetLearned() => _applyToCurrentSet(
        select: (word) => !word.isLearned,
        action: _service.markAsLearned,
      );

  /// Hoàn tác: bỏ đánh dấu mọi từ đã học của bộ đang mở. Tiến độ ôn tập
  /// (SRS) của các từ này bị xoá theo. Trả về số từ đã bỏ đánh dấu.
  Future<int> unmarkCurrentSetLearned() => _applyToCurrentSet(
        select: (word) => word.isLearned,
        action: _service.unmarkAsLearned,
      );

  /// Đổi trạng thái đã học của một từ trong bộ đang mở.
  Future<int> toggleWordLearned(Vocabulary word) => _applyToCurrentSet(
        select: (candidate) => candidate.id == word.id,
        action:
            word.isLearned ? _service.unmarkAsLearned : _service.markAsLearned,
      );

  /// Chạy [action] cho các từ [select] chọn trong bộ đang mở, rồi tải lại bộ
  /// và danh sách bộ. Lỗi giữa chừng được ném ra; những từ đã xử lý trước đó
  /// giữ nguyên, lần sau chỉ còn phần chưa xong.
  Future<int> _applyToCurrentSet({
    required bool Function(Vocabulary word) select,
    required Future<void> Function(String id) action,
  }) async {
    final detail = _detail.valueOrNull;
    if (detail == null || _isMarking) return 0;

    final targets = detail.words.where(select).toList();
    if (targets.isEmpty) return 0;

    _isMarking = true;
    _notify();
    try {
      for (final word in targets) {
        await action(word.id);
      }
      return targets.length;
    } finally {
      _isMarking = false;
      await loadSet(detail.set.id);
      if (_sets.hasData) await loadSets(silent: true);
    }
  }
}
