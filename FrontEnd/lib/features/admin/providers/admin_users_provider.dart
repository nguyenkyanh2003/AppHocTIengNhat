import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../../notifications/models/notification.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Danh sách tài khoản (tìm và lọc phía server, tải thêm theo trang), số đếm
/// toàn hệ thống và các thao tác quản trị trên một tài khoản.
class AdminUsersProvider extends AdminScreenProvider {
  AdminUsersProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;
  late final _users = PagedList<AdminUser>(onChanged: notify);
  ViewState<AdminUserStats> _stats = const ViewState.idle();
  AdminUserFilter _filter = AdminUserFilter.all;
  String? _search;

  ViewState<List<AdminUser>> get users => _users.state;
  bool get hasMore => _users.hasMore;
  bool get isLoadingMore => _users.isLoadingMore;
  String? get loadMoreError => _users.loadMoreError;
  bool get isRefreshing => _users.isRefreshing;
  ViewState<AdminUserStats> get stats => _stats;
  AdminUserFilter get filter => _filter;
  String? get search => _search;

  /// Tải danh sách theo bộ lọc đang chọn cùng số đếm toàn hệ thống.
  Future<void> load() => Future.wait([_loadUsers(), _loadStats()]);

  Future<void> loadMore() => _users.loadMore();

  Future<void> selectFilter(AdminUserFilter filter) {
    _filter = filter;
    return _loadUsers(keepCurrent: true);
  }

  Future<void> searchUsers(String query) {
    final trimmed = query.trim();
    _search = trimmed.isEmpty ? null : trimmed;
    return _loadUsers(keepCurrent: true);
  }

  Future<String?> setBanned(AdminUser user, bool banned) =>
      write(() => _service.updateUser(user.id, status: banned ? 'banned' : 'active'), refresh: _refresh);

  Future<String?> setAdmin(AdminUser user, bool admin) =>
      write(() => _service.updateUser(user.id, role: admin ? 'admin' : 'user'), refresh: _refresh);

  Future<String?> delete(AdminUser user) => write(() => _service.deleteUser(user.id), refresh: _refresh);

  /// Gửi thông báo cho [user], hoặc cho mọi người học khi [user] là `null`.
  /// Thành công thì là số người đã nhận.
  Future<ViewState<int>> sendNotification({
    AdminUser? user,
    required String title,
    required String message,
    required NotificationType type,
  }) =>
      ViewState.guard(() async {
        if (user == null) return _service.broadcastNotification(title: title, message: message, type: type);
        await _service.sendNotification(recipientId: user.id, title: title, message: message, type: type);
        return 1;
      });

  Future<void> _loadUsers({bool keepCurrent = false}) {
    final (search, filter) = (_search, _filter);
    return _users.load((page) => _service.users(page: page, search: search, filter: filter), keepCurrent: keepCurrent);
  }

  /// Số đếm chỉ là phần phụ: hỏng thì giữ số cũ, danh sách vẫn dùng được.
  Future<void> _loadStats() async {
    final result = await ViewState.guard(_service.userStats);
    if (result.hasData || !_stats.hasData) _stats = result;
    notify();
  }

  /// Sau một thao tác: danh sách tải lại theo đúng bộ lọc (tài khoản vừa khoá
  /// có thể không còn khớp bộ lọc), giữ bản cũ trong lúc chờ.
  Future<void> _refresh() => Future.wait([_users.reload(keepCurrent: true), _loadStats()]);
}
