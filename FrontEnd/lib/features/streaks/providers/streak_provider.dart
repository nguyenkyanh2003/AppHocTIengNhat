import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/leaderboard.dart';
import '../models/streak_settings.dart';
import '../models/user_streak.dart';
import '../services/streak_service.dart';

/// Chuỗi ngày học, lịch sử XP, cài đặt mục tiêu/nhắc học và bảng xếp hạng.
///
/// XP chỉ do server cấp sau khi chấm bài; muốn số mới nhất thì gọi
/// [loadStreak]. Mỗi khối có [ViewState] riêng: bảng xếp hạng lỗi không làm
/// hỏng màn chuỗi ngày.
class StreakProvider extends ChangeNotifier {
  StreakProvider({StreakService? service}) : _service = service ?? StreakService();

  final StreakService _service;

  ViewState<UserStreak> _streak = const ViewState.idle();
  ViewState<List<XPHistory>> _xpHistory = const ViewState.idle();
  ViewState<StreakSettings> _settings = const ViewState.idle();
  ViewState<Leaderboard> _leaderboard = const ViewState.idle();
  int _leaderboardGeneration = 0;
  bool _disposed = false;

  ViewState<UserStreak> get streakState => _streak;
  UserStreak? get currentStreak => _streak.valueOrNull;
  ViewState<List<XPHistory>> get xpHistoryState => _xpHistory;
  ViewState<StreakSettings> get settings => _settings;
  ViewState<Leaderboard> get leaderboard => _leaderboard;

  /// Tải tóm tắt streak; trả `true` khi đồng bộ được với server.
  ///
  /// Lỗi thì **giữ nguyên** dữ liệu đang có: mất mạng một lần không được xoá
  /// trắng màn hình, và bộ nhắc học cần biết lần đồng bộ này hỏng.
  Future<bool> loadStreak() => _reload(() => _streak, (state) => _streak = state, _service.getMyStreak);

  /// Tải cài đặt mục tiêu và nhắc học. Lần tải lại hỏng giữ bản đang có.
  Future<void> loadSettings() => _reload(() => _settings, (state) => _settings = state, _service.getSettings);

  /// Tải lịch sử XP. Lần tải lại hỏng giữ bản đang có.
  Future<void> loadXPHistory() => _reload(() => _xpHistory, (state) => _xpHistory = state, _service.getXPHistory);

  /// Lưu cài đặt. Trả `null` khi lưu được, ngược lại là câu báo lỗi để hiện
  /// ngay trong màn cài đặt.
  Future<String?> saveSettings({int? dailyGoalXp, bool? reminderEnabled, String? reminderTime}) async {
    final result = await ViewState.guard(
      () => _service.updateSettings(dailyGoalXp: dailyGoalXp, reminderEnabled: reminderEnabled, reminderTime: reminderTime),
    );
    if (!result.hasData) return result.errorOrNull;
    _settings = result;
    _notify();
    // Thẻ mục tiêu đọc từ tóm tắt, nên tải lại để hai nơi khớp nhau.
    await loadStreak();
    return null;
  }

  /// Đổi kỳ là tải lại cả bảng; phản hồi của kỳ cũ về muộn bị bỏ.
  Future<void> loadLeaderboard({String period = 'all', int limit = 50}) async {
    final generation = ++_leaderboardGeneration;
    _leaderboard = const ViewState.loading();
    _notify();
    final result = await ViewState.guard(() => _service.getLeaderboard(period: period, limit: limit));
    if (generation != _leaderboardGeneration) return;
    _leaderboard = result;
    _notify();
  }

  /// Xoá mọi trạng thái, dùng khi đăng xuất.
  void clear() {
    _leaderboardGeneration++;
    _streak = const ViewState.idle();
    _xpHistory = const ViewState.idle();
    _settings = const ViewState.idle();
    _leaderboard = const ViewState.idle();
    _notify();
  }

  /// Lần đầu thì đi qua loading; đã có dữ liệu thì giữ nguyên trong lúc chờ và
  /// khi lần tải lại hỏng. Trả `true` khi lần tải này thành công.
  Future<bool> _reload<T>(
    ViewState<T> Function() read,
    void Function(ViewState<T> state) write,
    Future<T> Function() fetch,
  ) async {
    if (!read().hasData) {
      write(const ViewState.loading());
      _notify();
    }
    final result = await ViewState.guard(fetch);
    if (result.hasData || !read().hasData) write(result);
    _notify();
    return result.hasData;
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
