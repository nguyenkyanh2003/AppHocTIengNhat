import 'package:flutter/foundation.dart';

import '../../../core/state/detail_state.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

/// Luyện tập: danh sách bài tập, đề đang làm, nộp bài, lịch sử và kết quả.
class ExerciseProvider extends ChangeNotifier {
  ExerciseProvider({ExerciseService? service}) : _service = service ?? ExerciseService();

  final ExerciseService _service;
  ViewState<List<Exercise>> _exercises = const ViewState.idle();
  int _listGeneration = 0;
  late final _detail = DetailState<Exercise>(idOf: (exercise) => exercise.id, onChanged: _notify);
  late final _result = DetailState<ExerciseResult>(idOf: (result) => result.id, onChanged: _notify);
  late final _history = PagedList<ExerciseResult>(onChanged: _notify);
  bool _submitting = false;
  bool _disposed = false;

  ViewState<List<Exercise>> get exercises => _exercises;
  ViewState<List<ExerciseResult>> get history => _history.state;
  bool get hasMoreHistory => _history.hasMore;
  bool get isLoadingMoreHistory => _history.isLoadingMore;
  String? get loadMoreHistoryError => _history.loadMoreError;
  bool get isSubmitting => _submitting;

  ViewState<Exercise> detailOf(String id) => _detail.of(id);
  ViewState<ExerciseResult> resultOf(String id) => _result.of(id);

  /// Bài tập của một bài học, hoặc mọi bài tập khi không có [lessonId].
  Future<void> loadExercises({String? lessonId}) async {
    final generation = ++_listGeneration;
    _exercises = const ViewState.loading();
    _notify();

    final result = await ViewState.guard(() => lessonId == null ? _service.listAll() : _service.listByLesson(lessonId));
    if (generation != _listGeneration) return;
    _exercises = result;
    _notify();
  }

  Future<void> loadDetail(String id) => _detail.load(id, () => _service.detail(id));

  Future<void> loadResult(String id) => _result.load(id, () => _service.result(id));

  Future<void> loadHistory() => _history.load((page) => _service.history(page: page));

  Future<void> loadMore() => _history.loadMore();

  /// Nộp bài; kết quả (hoặc câu báo lỗi) trả về cho màn chuyển trang. Lỗi thì
  /// người học giữ nguyên bài làm và nộp lại với cùng [attemptId].
  Future<ViewState<ExerciseResult>> submit(
    String exerciseId, {
    required Map<String, String> answers,
    required int timeSpent,
    required String attemptId,
  }) async {
    if (_submitting) return const ViewState.failure('Bài làm đang được nộp.');
    _submitting = true;
    _notify();

    final result = await ViewState.guard(
      () => _service.submit(exerciseId, answers: answers, timeSpent: timeSpent, attemptId: attemptId),
    );
    _submitting = false;
    _notify();
    if (result.hasData && _history.state is! ViewIdle) _history.reload();
    return result;
  }

  /// Về trạng thái chưa tải (đăng xuất).
  void clear() {
    _listGeneration++;
    _exercises = const ViewState.idle();
    _detail.clear();
    _result.clear();
    _history.clear();
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
