import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Gửi báo cáo
  Future<bool> createReport({
    required String type,
    required String title,
    required String description,
    String? relatedId,
    String? relatedType,
    String priority = 'medium',
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final report = await _reportService.createReport(
        type: type,
        title: title,
        description: description,
        relatedId: relatedId,
        relatedType: relatedType,
        priority: priority,
      );

      if (report != null) {
        _successMessage =
            'Gửi báo cáo thành công! Chúng tôi sẽ xử lý trong thời gian sớm nhất.';
        notifyListeners();
        return true;
      } else {
        _error = 'Không thể gửi báo cáo';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('Error creating report: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy báo cáo của user
  Future<void> loadMyReports({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reports = await _reportService.getMyReports(
        page: page,
        limit: limit,
        status: status,
      );

      if (reports != null) {
        _reports = reports;
      } else {
        _error = 'Không thể tải dữ liệu';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa báo cáo
  Future<bool> deleteReport(String reportId) async {
    try {
      final success = await _reportService.deleteReport(reportId);
      if (success) {
        _reports.removeWhere((r) => r.id == reportId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    }
  }

  /// Reset messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
