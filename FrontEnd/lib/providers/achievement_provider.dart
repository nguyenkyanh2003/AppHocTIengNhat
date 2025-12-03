import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _earnedAchievements = [];
  List<UserAchievement> _lockedAchievements = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  List<Achievement> get allAchievements => _allAchievements;
  List<UserAchievement> get earnedAchievements => _earnedAchievements;
  List<UserAchievement> get lockedAchievements => _lockedAchievements;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAchievements => _allAchievements.length;
  int get completedAchievements => _earnedAchievements.where((a) => a.isCompleted).length;
  
  double get completionRate {
    if (totalAchievements == 0) return 0.0;
    return completedAchievements / totalAchievements;
  }

  // Load all achievements
  Future<void> loadAllAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allAchievements = await _achievementService.getAllAchievements();
      _error = null;
    } catch (e) {
      _error = 'Không thể tải danh sách achievement';
      print('Error loading achievements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's achievements
  Future<void> loadMyAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _achievementService.getMyAchievements();
      
      if (result != null) {
        final earned = result['earned'] as List?;
        if (earned != null) {
          _earnedAchievements = earned
              .map((item) => UserAchievement.fromJson(item))
              .toList();
        }
        
        final locked = result['locked'] as List?;
        if (locked != null) {
          _lockedAchievements = locked
              .map((item) => UserAchievement.fromJson(item))
              .toList();
        }
        
        _error = null;
      }
    } catch (e) {
      _error = 'Không thể tải achievement của bạn';
      print('Error loading user achievements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load achievements by category
  Future<Map<String, dynamic>?> loadAchievementsByCategory(String category) async {
    try {
      return await _achievementService.getAchievementsByCategory(category);
    } catch (e) {
      print('Error loading category achievements: $e');
      return null;
    }
  }

  // Update achievement progress
  Future<bool> updateProgress(String achievementId, int progress) async {
    try {
      final result = await _achievementService.updateProgress(achievementId, progress);
      
      if (result != null) {
        // Reload achievements to reflect changes
        await loadMyAchievements();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating achievement progress: $e');
      return false;
    }
  }

  // Load achievement statistics
  Future<void> loadStats() async {
    try {
      final result = await _achievementService.getStats();
      if (result != null) {
        _stats = result;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading achievement stats: $e');
    }
  }

  // Get achievements by category (from loaded data)
  List<UserAchievement> getAchievementsByCategory(String category) {
    return [..._earnedAchievements, ..._lockedAchievements]
        .where((ua) => ua.achievement.category == category)
        .toList();
  }

  // Check if achievement is earned
  bool isAchievementEarned(String achievementId) {
    return _earnedAchievements.any((ua) => 
      ua.achievement.id == achievementId && ua.isCompleted
    );
  }

  // Get achievement progress
  int? getAchievementProgress(String achievementId) {
    final achievement = [..._earnedAchievements, ..._lockedAchievements]
        .firstWhere(
          (ua) => ua.achievement.id == achievementId,
          orElse: () => UserAchievement(
            id: '',
            userId: '',
            achievement: Achievement(
              id: '',
              name: '',
              nameVi: '',
              description: '',
              descriptionVi: '',
              icon: '',
              category: 'practice',
              requirementType: 'count',
              requirementValue: 0,
              xpReward: 0,
              rarity: 'common',
              isActive: true,
            ),
            earnedAt: DateTime.now(),
            progress: 0,
            isCompleted: false,
          ),
        );
    
    return achievement.progress;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _allAchievements = [];
    _earnedAchievements = [];
    _lockedAchievements = [];
    _stats = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _allAchievements = [];
    _earnedAchievements = [];
    _lockedAchievements = [];
    _stats = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
