import '../../../core/network/api_client.dart';

class TransactionService {
  TransactionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Gửi yêu cầu đăng ký gói. Chưa nối cổng thanh toán nên yêu cầu nằm chờ
  /// quản trị viên duyệt; người dùng và trạng thái do server đặt.
  Future<void> createSubscriptionRequest({required String packageId, required int amount}) =>
      _client.post('/transactions/create', {
        'type': 'SUBSCRIPTION',
        'amount': amount,
        'currency': 'VND',
        'payment_method': 'NONE',
        'package_id': packageId,
        'description': 'Đăng ký gói $packageId',
      });
}
