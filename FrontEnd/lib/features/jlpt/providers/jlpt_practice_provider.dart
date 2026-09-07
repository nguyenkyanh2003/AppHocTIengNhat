import 'package:flutter/foundation.dart';
import '../services/jlpt_service.dart';

class JLPTPracticeProvider with ChangeNotifier {
  final JLPTService _service = JLPTService();

  bool _loading = false;
  List<dynamic> _items = [];
  bool get isLoading => _loading;
  List<dynamic> get items => _items;

  Future<void> loadPractice(
      {required String type, String? level, int limit = 10}) async {
    _loading = true;
    _items = [];
    notifyListeners();
    try {
      final data =
          await _service.fetchPractice(type: type, level: level, limit: limit);
      _items = data;
    } catch (e) {
      debugPrint('Error load practice: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
