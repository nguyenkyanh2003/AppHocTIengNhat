import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/state/view_state.dart';
import '../models/leaderboard.dart';
import '../models/streak_settings.dart';
import '../models/user_streak.dart';
import '../services/streak_service.dart';

class StreakProvider with ChangeNotifier {
  StreakProvider({StreakService? service}) : _streakService = service ?? StreakService();

  final StreakService _streakService;

  UserStreak? _currentStreak;
  List<XPHistory> _xpHistory = [];
  List<LeaderboardEntry> _leaderboard = [];
  int? _userRank;
  bool _isLoading = false;
  String? _error;
  ViewState<StreakSettings> _settings = const ViewState.idle();

  UserStreak? get currentStreak => _currentStreak;
  List<XPHistory> get xpHistory => _xpHistory;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  int? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _error = 'Không thể tải dữ liệu streak';
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

  // Tải lịch sử XP
  Future<void> loadXPHistory() async {
    try {
      _xpHistory = await _streakService.getXPHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi tải lịch sử XP: $e');
    }
  }

  // Tải bảng xếp hạng
  Future<void> loadLeaderboard({String period = 'all', int limit = 50}) async {
    _isLoading = true;
    _error = null;
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
        _error = null;
      }
    } catch (e) {
      _error = 'Không thể tải bảng xếp hạng';
      debugPrint('Lỗi khi tải bảng xếp hạng: $e');
    } finally {
      _isLoading = false;
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
    _xpHistory = [];
    _leaderboard = [];
    _userRank = null;
    _isLoading = false;
    _error = null;
    _settings = const ViewState.idle();
    notifyListeners();
  }
}
