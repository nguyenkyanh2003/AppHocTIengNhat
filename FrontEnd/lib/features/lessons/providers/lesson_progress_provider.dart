import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/lesson_progress.dart';
import '../services/lesson_progress_service.dart';

/// Tiến độ của người học trên từng bài, cho màn chi tiết bài. Phiên học
/// (`LessonStudySession`) tự gọi service để đánh dấu và hoàn thành.
class LessonProgressProvider extends ChangeNotifier {
  LessonProgressProvider({LessonProgressService? service}) : _service = service ?? LessonProgressService();

  final LessonProgressService _service;
  final Map<String, ViewState<LessonProgress?>> _progress = {};
  final Map<String, int> _generations = {};
  bool _disposed = false;

  /// Tiến độ bài [lessonId]; `data(null)` là chưa bắt đầu bài.
  ViewState<LessonProgress?> progressOf(String lessonId) => _progress[lessonId] ?? const ViewState.loading();

  /// Tải lại tiến độ (sau khi học xong một bước). Đang có thì giữ trong lúc chờ.
  Future<void> loadProgress(String lessonId) async {
    final generation = _generations[lessonId] = (_generations[lessonId] ?? 0) + 1;
    if (!(_progress[lessonId]?.hasData ?? false)) {
      _progress[lessonId] = const ViewState.loading();
      _notify();
    }
    final result = await ViewState.guard(() => _service.getProgress(lessonId));
    if (generation != _generations[lessonId]) return;
    _progress[lessonId] = result;
    _notify();
  }

  /// Học lại từ đầu; trả `null` khi xong hoặc câu báo lỗi.
  Future<String?> resetProgress(String lessonId) async {
    final result = await ViewState.guard(() => _service.resetProgress(lessonId));
    if (!result.hasData) return result.errorOrNull;
    _generations[lessonId] = (_generations[lessonId] ?? 0) + 1;
    _progress[lessonId] = const ViewState.data(null);
    _notify();
    return null;
  }

  /// Xoá state (đăng xuất); phản hồi đang chạy của phiên trước bị bỏ.
  void clear() {
    _generations.updateAll((_, generation) => generation + 1);
    _progress.clear();
    _notify();
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
