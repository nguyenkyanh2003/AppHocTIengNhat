import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/state/view_state.dart';
import '../models/leaderboard.dart';
import '../models/streak_settings.dart';
import '../models/user_streak.dart';
import '../services/streak_service.dart';

class StreakProvider with ChangeNotifier {
  StreakProvider({StreakService? service})
      : _streakService = service ?? StreakService();

  final StreakService _streakService;

  UserStreak? _currentStreak;
  ViewState<List<XPHistory>> _xpHistoryState = const ViewState.idle();
  List<LeaderboardEntry> _leaderboard = [];
  int? _userRank;
  bool _isLoading = false;
  String? _error;
  bool _isLoadingLeaderboard = false;
  String? _leaderboardError;
  ViewState<StreakSettings> _settings = const ViewState.idle();

  UserStreak? get currentStreak => _currentStreak;
  List<XPHistory> get xpHistory => _xpHistoryState.valueOrNull ?? const [];

  /// Lịch sử XP kèm trạng thái, cho màn phải phân biệt rỗng với lỗi.
  ViewState<List<XPHistory>> get xpHistoryState => _xpHistoryState;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  int? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Tóm tắt streak kèm trạng thái, cho khối phải phân biệt "chưa tải được" với số 0.
  ViewState<UserStreak> get streakState => ViewState.fromLegacy(
        isLoading: _isLoading,
        error: _error,
        value: _currentStreak,
      );

  /// Bảng xếp hạng có trạng thái riêng: lỗi của nó không được làm hỏng màn chuỗi ngày.
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get leaderboardError => _leaderboardError;

  /// Cài đặt mục tiêu ngày và nhắc học.
  ViewState<StreakSettings> get settings => _settings;

  /// Tải tóm tắt streak. Trả `true` khi đồng bộ được với server.
  ///
  /// Lỗi thì **giữ nguyên** dữ liệu đang có: mất mạng một lần không được xoá
  /// trắng màn hình, và người gọi (bộ nhắc học) cần biết lần đồng bộ này hỏng.
  Future<bool> loadStreak() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStreak = await _streakService.getMyStreak();
      return true;
    } catch (e) {
      _error = userMessageOf(e);
      debugPrint('Lỗi khi tải streak: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải cài đặt mục tiêu và nhắc học. Lần tải lại hỏng giữ bản đang có.
  Future<void> loadSettings() async {
    if (!_settings.hasData) {
      _settings = const ViewState.loading();
      notifyListeners();
    }
    final result = await ViewState.guard(_streakService.getSettings);
    if (result.hasData || !_settings.hasData) _settings = result;
    notifyListeners();
  }

  /// Lưu cài đặt. Trả `null` khi lưu được, ngược lại là câu báo lỗi để hiện
  /// ngay trong màn cài đặt.
  Future<String?> saveSettings({
    int? dailyGoalXp,
    bool? reminderEnabled,
    String? reminderTime,
  }) async {
    final result = await ViewState.guard(
      () => _streakService.updateSettings(
        dailyGoalXp: dailyGoalXp,
        reminderEnabled: reminderEnabled,
        reminderTime: reminderTime,
      ),
    );
    if (result is! ViewData<StreakSettings>) {
      return result.errorOrNull ?? 'Không lưu được cài đặt.';
    }

    _settings = result;
    notifyListeners();
    // Thẻ mục tiêu đọc từ tóm tắt, nên tải lại để hai nơi khớp nhau.
    await loadStreak();
    return null;
  }

  // Không còn `addXP`: XP chỉ đến từ server sau khi chấm bài. Muốn số liệu
  // mới nhất thì gọi `loadStreak()`.

  /// Tải lịch sử XP. Lần tải lại hỏng giữ bản đang có.
  Future<void> loadXPHistory() async {
    if (!_xpHistoryState.hasData) {
      _xpHistoryState = const ViewState.loading();
      notifyListeners();
    }
    final result = await ViewState.guard(_streakService.getXPHistory);
    if (result.hasData || !_xpHistoryState.hasData) _xpHistoryState = result;
    notifyListeners();
  }

  // Tải bảng xếp hạng
  Future<void> loadLeaderboard({String period = 'all', int limit = 50}) async {
    _isLoadingLeaderboard = true;
    _leaderboardError = null;
    notifyListeners();

    try {
      final result = await _streakService.getLeaderboard(
        period: period,
        limit: limit,
      );

      if (result != null) {
        final leaderboardData = result['leaderboard'] as List?;
        if (leaderboardData != null) {
          _leaderboard = leaderboardData
              .map((item) => LeaderboardEntry.fromJson(item))
              .toList();
        }

        _userRank = result['user_rank'];
      }
    } catch (e) {
      _leaderboardError = userMessageOf(e);
      debugPrint('Lỗi khi tải bảng xếp hạng: $e');
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // Helper methods
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() => clear();

  /// Xoá mọi trạng thái, dùng khi đăng xuất.
  void clear() {
    _currentStreak = null;
    _xpHistoryState = const ViewState.idle();
    _leaderboard = [];
    _userRank = null;
    _isLoading = false;
    _error = null;
    _isLoadingLeaderboard = false;
    _leaderboardError = null;
    _settings = const ViewState.idle();
    notifyListeners();
  }
}
