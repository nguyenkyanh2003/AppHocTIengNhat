import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_streak.dart';
import '../models/leaderboard.dart';
import '../services/streak_service.dart';

class StreakProvider with ChangeNotifier {
  final StreakService _streakService = StreakService();

  UserStreak? _currentStreak;
  List<XPHistory> _xpHistory = [];
  List<LeaderboardEntry> _leaderboard = [];
  int? _userRank;
  bool _isLoading = false;
  String? _error;

  UserStreak? get currentStreak => _currentStreak;
  List<XPHistory> get xpHistory => _xpHistory;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  int? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's streak data
  Future<void> loadStreak() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔥 Loading streak data from API...');
      _currentStreak = await _streakService.getMyStreak();
      if (_currentStreak != null) {
        debugPrint('✅ Streak loaded - XP: ${_currentStreak!.totalXP}, Streak: ${_currentStreak!.currentStreak} days, Level: ${_currentStreak!.level}');
      }
      _error = null;
    } catch (e) {
      _error = 'Không thể tải dữ liệu streak';
      debugPrint('❌ Error loading streak: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm XP (tự động cập nhật streak khi có hoạt động học tập)
  Future<bool> addXP(int amount, String reason) async {
    try {
      final result = await _streakService.addXP(amount, reason);
      
      if (result != null) {
        // Cập nhật streak từ response (bao gồm cả streak info)
        if (_currentStreak != null) {
          _currentStreak = _currentStreak!.copyWith(
            totalXP: result['total_xp'],
            level: result['level'],
            xpToNextLevel: result['xp_to_next_level'],
            currentStreak: result['current_streak'],
            longestStreak: result['longest_streak'],
          );
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      print('Lỗi khi thêm XP: $e');
      return false;
    }
  }

  // Tải lịch sử XP
  Future<void> loadXPHistory() async {
    try {
      _xpHistory = await _streakService.getXPHistory();
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tải lịch sử XP: $e');
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
      print('Lỗi khi tải bảng xếp hạng: $e');
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

  void reset() {
    _currentStreak = null;
    _xpHistory = [];
    _leaderboard = [];
    _userRank = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _currentStreak = null;
    _xpHistory = [];
    _leaderboard = [];
    _userRank = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
