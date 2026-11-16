import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/admin_transaction.dart';
import '../services/admin_service.dart';
import 'admin_screen_provider.dart';

/// Giao dịch chờ duyệt và lịch sử thanh toán, lọc theo trạng thái phía server.
class AdminTransactionsProvider extends AdminScreenProvider {
  AdminTransactionsProvider({AdminService? service}) : _service = service ?? AdminService();

  static const statuses = {
    'pending': 'Chờ xử lý',
    'processing': 'Đang xử lý',
    'completed': 'Hoàn thành',
    'failed': 'Thất bại',
    'refunded': 'Hoàn tiền',
    'cancelled': 'Đã hủy',
  };

  final AdminService _service;
  late final _transactions = PagedList<AdminTransaction>(onChanged: notify);
  String? _status;

  ViewState<List<AdminTransaction>> get transactions => _transactions.state;
  bool get hasMore => _transactions.hasMore;
  bool get isLoadingMore => _transactions.isLoadingMore;
  String? get loadMoreError => _transactions.loadMoreError;
  bool get isRefreshing => _transactions.isRefreshing;

  /// `null` là mọi trạng thái.
  String? get status => _status;

  Future<void> load({bool keepCurrent = false}) {
    final status = _status;
    return _transactions.load((page) => _service.transactions(page: page, status: status), keepCurrent: keepCurrent);
  }

  Future<void> loadMore() => _transactions.loadMore();

  Future<void> selectStatus(String? status) {
    _status = status;
    return load(keepCurrent: true);
  }

  Future<String?> updateStatus(AdminTransaction transaction, String status) => write(
        () => _service.updateTransactionStatus(transaction.id, status),
        refresh: () => _transactions.reload(keepCurrent: true),
      );
}
