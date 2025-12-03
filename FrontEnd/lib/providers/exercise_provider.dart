import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();

  List<Exercise> _exercises = [];
  Exercise? _currentExercise;
  ExerciseResult? _currentResult;
  List<ExerciseResult> _history = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Exercise> get exercises => _exercises;
  Exercise? get currentExercise => _currentExercise;
  ExerciseResult? get currentResult => _currentResult;
  List<ExerciseResult> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy tất cả bài tập
  Future<void> loadAllExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getAllExercises();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách bài tập theo bài học
  Future<void> loadExercisesByLesson(String lessonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getExercisesByLesson(lessonId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách bài tập theo level
  Future<void> loadExercisesByLevel(String level) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getExercisesByLevel(level);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách bài tập theo type
  Future<void> loadExercisesByType(String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getExercisesByType(type);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy chi tiết bài tập
  Future<void> loadExerciseDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentExercise = await _exerciseService.getExerciseById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Nộp bài
  Future<bool> submitExercise(
    String exerciseId,
    List<UserAnswer> answers,
    int timeSpent,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentResult = await _exerciseService.submitExercise(
        exerciseId,
        answers,
        timeSpent,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy lịch sử làm bài
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _exerciseService.getUserExerciseHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy kết quả chi tiết
  Future<void> loadResultDetail(String resultId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentResult = await _exerciseService.getResultById(resultId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current exercise
  void clearCurrentExercise() {
    _currentExercise = null;
    _currentResult = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _exercises = [];
    _currentExercise = null;
    _currentResult = null;
    _history = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
