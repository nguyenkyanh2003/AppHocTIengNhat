import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

/// Huy hiệu của người học, dùng cho màn Thành tích và khối "Thành tích gần đây".
class AchievementProvider with ChangeNotifier {
  AchievementProvider({AchievementService? service})
      : _service = service ?? AchievementService();

  final AchievementService _service;

  ViewState<MyAchievements> _mine = const ViewState.idle();

  /// Lượt tải mới nhất: phản hồi về muộn của lượt cũ, hay của tài khoản vừa đăng
  /// xuất, không được ghi đè.
  int _request = 0;

  ViewState<MyAchievements> get mine => _mine;

  /// Trả về câu báo lỗi nếu tải hỏng. Đã có dữ liệu thì giữ nguyên để màn hình báo
  /// nhẹ: mất mạng một lần không được xoá trắng danh sách.
  Future<String?> loadMyAchievements() async {
    final request = ++_request;
    final hadData = _mine.hasData;
    if (!hadData) {
      _mine = const ViewState.loading();
      notifyListeners();
    }

    final result = await ViewState.guard(_service.getMyAchievements);
    if (request != _request) return null;

    if (!hadData || result.hasData) {
      _mine = result;
      notifyListeners();
    }
    return result.errorOrNull;
  }

  void clear() {
    _request++;
    _mine = const ViewState.idle();
    notifyListeners();
  }
}
