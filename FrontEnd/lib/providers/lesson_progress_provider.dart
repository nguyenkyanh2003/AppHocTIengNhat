import 'package:flutter/material.dart';
import '../models/lesson_progress.dart';
import '../services/lesson_progress_service.dart';

class LessonProgressProvider extends ChangeNotifier {
  final LessonProgressService _progressService = LessonProgressService();

  // Progress cho lesson hiện tại
  LessonProgress? _currentProgress;
  LessonProgress? get currentProgress => _currentProgress;

  // Danh sách tất cả progress
  List<LessonProgress> _allProgress = [];
  List<LessonProgress> get allProgress => _allProgress;

  // Stats tổng quan
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Lấy tiến độ cho một lesson
  Future<void> loadProgress(String lessonId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentProgress = await _progressService.getProgress(lessonId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy tất cả tiến độ
  Future<void> loadAllProgress() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allProgress = await _progressService.getAllProgress();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bắt đầu học một lesson
  Future<bool> startLesson(String lessonId) async {
    try {
      _error = null;
      
      final progress = await _progressService.startLesson(lessonId);
      if (progress != null) {
        _currentProgress = progress;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật tiến độ
  Future<bool> updateProgress({
    required String lessonId,
    required String itemType,
    required String itemId,
    required bool completed,
  }) async {
    try {
      _error = null;
      
      final progress = await _progressService.updateProgress(
        lessonId: lessonId,
        itemType: itemType,
        itemId: itemId,
        completed: completed,
      );
      
      if (progress != null) {
        _currentProgress = progress;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hoàn thành lesson
  Future<bool> completeLesson(String lessonId) async {
    try {
      _error = null;
      
      final progress = await _progressService.completeLesson(lessonId);
      if (progress != null) {
        _currentProgress = progress;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reset tiến độ
  Future<bool> resetProgress(String lessonId) async {
    try {
      _error = null;
      
      final success = await _progressService.resetProgress(lessonId);
      if (success) {
        _currentProgress = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Lấy thống kê
  Future<void> loadStats() async {
    try {
      _error = null;
      _stats = await _progressService.getOverallStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Kiểm tra xem lesson đã được bắt đầu chưa
  bool isLessonStarted(String lessonId) {
    if (_currentProgress == null) return false;
    return _currentProgress!.lessonId == lessonId;
  }

  /// Kiểm tra xem lesson đã hoàn thành chưa
  bool isLessonCompleted(String lessonId) {
    if (_currentProgress == null) return false;
    return _currentProgress!.lessonId == lessonId && 
           _currentProgress!.isCompleted;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear current progress
  void clearCurrentProgress() {
    _currentProgress = null;
    notifyListeners();
  }
  
  /// Clear all data (for logout)
  void clear() {
    _currentProgress = null;
    _allProgress = [];
    _stats = {};
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
