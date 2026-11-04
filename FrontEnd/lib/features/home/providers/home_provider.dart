import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../../lessons/models/lesson_level.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/next_lesson.dart';
import '../services/home_service.dart';

/// Trạng thái các khối dữ liệu riêng của Trang chủ: bài học tiếp theo và từ
/// mới hôm nay. Chuỗi ngày / XP, tin tức và số thông báo chưa đọc đã có
/// provider riêng (`StreakProvider`, `NewsProvider`, `NotificationProvider`).
class HomeProvider extends ChangeNotifier {
  HomeProvider({HomeService? service, DateTime Function()? clock})
      : _service = service ?? HomeService(),
        _clock = clock ?? DateTime.now;

  final HomeService _service;
  final DateTime Function() _clock;

  ViewState<NextLesson?> _nextLesson = const ViewState.idle();
  ViewState<Vocabulary?> _wordOfDay = const ViewState.idle();
  int _generation = 0;

  ViewState<NextLesson?> get nextLesson => _nextLesson;
  ViewState<Vocabulary?> get wordOfDay => _wordOfDay;

  /// Nạp (lại) cả hai khối song song. Khối nào lỗi thì chỉ khối đó báo lỗi.
  ///
  /// Đang có dữ liệu thì giữ nguyên trong lúc làm mới (kéo xuống để làm mới),
  /// không chớp về trạng thái đang tải.
  Future<void> load({required String? userLevel}) async {
    final generation = ++_generation;
    final lessonLevel = defaultLessonLevel(userLevel);
    final wordLevel = normalizeJlptLevel(userLevel) ?? kLessonLevels.first;
    if (!_nextLesson.hasData) _nextLesson = const ViewState.loading();
    if (!_wordOfDay.hasData) _wordOfDay = const ViewState.loading();
    notifyListeners();

    final results = await Future.wait([
      ViewState.guard(
          () => _service.loadNextLesson(fallbackLevel: lessonLevel)),
      ViewState.guard(
          () => _service.loadWordOfDay(level: wordLevel, today: _clock())),
    ]);
    // Đăng xuất / đổi tài khoản trong lúc chờ: kết quả của lần nạp cũ bỏ đi.
    if (generation != _generation) return;

    _nextLesson =
        _keepOnFailure(_nextLesson, results[0] as ViewState<NextLesson?>);
    _wordOfDay =
        _keepOnFailure(_wordOfDay, results[1] as ViewState<Vocabulary?>);
    notifyListeners();
  }

  /// Làm mới thất bại mà đang có dữ liệu thì giữ dữ liệu cũ.
  ViewState<T> _keepOnFailure<T>(ViewState<T> current, ViewState<T> next) =>
      next is ViewFailure<T> && current.hasData ? current : next;

  void clear() {
    _generation++;
    _nextLesson = const ViewState.idle();
    _wordOfDay = const ViewState.idle();
    notifyListeners();
  }
}
