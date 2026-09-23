import 'package:flutter/foundation.dart';

import '../services/export_service.dart';

/// Trạng thái một lần xuất dữ liệu, kèm huỷ giữa chừng.
///
/// Huỷ không ngắt request đang chạy mà đánh dấu lần xuất đó là đã bỏ: service
/// dừng ở trang kế tiếp và ném [ExportCancelled], nên không tệp nào được tạo.
class ExportProvider extends ChangeNotifier {
  ExportProvider({ExportService? service}) : _service = service ?? ExportService();

  final ExportService _service;

  bool _exporting = false;
  int _generation = 0;
  bool _disposed = false;

  bool get isExporting => _exporting;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<Map<String, dynamic>> load(String type) async {
    final generation = ++_generation;
    _exporting = true;
    _notify();
    try {
      return await _service.load(type, isCancelled: () => generation != _generation || _disposed);
    } finally {
      if (generation == _generation) {
        _exporting = false;
        _notify();
      }
    }
  }

  void cancel() {
    if (!_exporting) return;
    _generation++;
    _exporting = false;
    _notify();
  }
}
