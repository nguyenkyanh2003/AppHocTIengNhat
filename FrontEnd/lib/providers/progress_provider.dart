import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  DashboardStats? _stats;
  List<TimelineData> _timeline = [];
  List<HeatmapData> _heatmap = [];
  DashboardBreakdown? _breakdown;

  bool _isLoading = false;
  String? _error;
  String _selectedPeriod = 'week';

  DashboardStats? get stats => _stats;
  List<TimelineData> get timeline => _timeline;
  List<HeatmapData> get heatmap => _heatmap;
  DashboardBreakdown? get breakdown => _breakdown;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPeriod => _selectedPeriod;

  // Load tất cả dữ liệu dashboard
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadStats(),
        loadTimeline(),
        loadHeatmap(),
        loadBreakdown(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Không thể tải dữ liệu dashboard';
      print('Lỗi khi tải dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load thống kê tổng quan
  Future<void> loadStats() async {
    try {
      _stats = await _progressService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tải stats: $e');
    }
  }

  // Load timeline
  Future<void> loadTimeline({String? period}) async {
    if (period != null) {
      _selectedPeriod = period;
    }
    
    try {
      _timeline = await _progressService.getTimeline(period: _selectedPeriod);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tải timeline: $e');
    }
  }

  // Load heatmap
  Future<void> loadHeatmap({int? year}) async {
    try {
      _heatmap = await _progressService.getHeatmap(year: year);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tải heatmap: $e');
    }
  }

  // Load breakdown
  Future<void> loadBreakdown() async {
    try {
      _breakdown = await _progressService.getBreakdown();
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tải breakdown: $e');
    }
  }

  // Change period và reload timeline
  Future<void> changePeriod(String period) async {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      await loadTimeline(period: period);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _stats = null;
    _timeline = [];
    _heatmap = [];
    _breakdown = null;
    _isLoading = false;
    _error = null;
    _selectedPeriod = 'week';
    notifyListeners();
  }
}
