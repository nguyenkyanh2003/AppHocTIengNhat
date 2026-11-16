import '../../../core/state/view_state.dart';
import '../models/admin_achievement.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Định nghĩa huy hiệu và số người đã mở từng huy hiệu.
class AdminAchievementsProvider extends AdminScreenProvider {
  AdminAchievementsProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;
  ViewState<List<AdminAchievement>> _achievements = const ViewState.idle();

  ViewState<List<AdminAchievement>> get achievements => _achievements;

  /// Lần tải lại hỏng (sau một thao tác ghi) giữ danh sách đang hiện.
  Future<void> load() async {
    if (!_achievements.hasData) {
      _achievements = const ViewState.loading();
      notify();
    }
    final result = await ViewState.guard(_service.achievements);
    if (result.hasData || !_achievements.hasData) _achievements = result;
    notify();
  }

  /// Ba thao tác ghi trả `null` khi xong, ngược lại là câu báo lỗi: hộp thoại
  /// hiện lỗi tại chỗ, danh sách đang có không bị thay bằng màn lỗi.
  Future<String?> create(AchievementDraft draft) => write(() => _service.createAchievement(draft), refresh: load);

  Future<String?> update(String id, AchievementDraft draft) =>
      write(() => _service.updateAchievement(id, draft), refresh: load);

  Future<String?> delete(String id) => write(() => _service.deleteAchievement(id), refresh: load);
}
