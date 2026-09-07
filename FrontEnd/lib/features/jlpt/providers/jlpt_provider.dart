import 'package:flutter/foundation.dart';
import '../models/jlpt_models.dart';
import '../services/jlpt_service.dart';

class JLPTProvider with ChangeNotifier {
  final JLPTService _service = JLPTService();

  List<JLPTExamBrief> _exams = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _level;
  int? _year;
  int? _month;

  List<JLPTExamBrief> get exams => _exams;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get level => _level;
  int? get year => _year;
  int? get month => _month;

  Future<void> loadExams({
    bool refresh = false,
    String? level,
    int? year,
    int? month,
    int page = 1,
  }) async {
    _isLoading = true;
    if (refresh) _exams = [];
    notifyListeners();

    _level = level;
    _year = year;
    _month = month;

    try {
      final resp = await _service.fetchExams(
        level: level,
        year: year,
        month: month,
        page: page,
      );
      _currentPage = resp['current'] as int? ?? 1;
      _totalPages = resp['pages'] as int? ?? 1;
      final data = resp['data'] as List<JLPTExamBrief>;
      if (refresh || page == 1) {
        _exams = data;
      } else {
        _exams = [..._exams, ...data];
      }
    } catch (e) {
      debugPrint('Error load exams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
