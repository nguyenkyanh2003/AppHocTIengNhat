import '../../../core/network/api_client.dart';

class TransactionService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> createSubscriptionRequest({
    required String packageId,
    required int amount,
  }) {
    return _client.post('/transactions/create', {
      'type': 'SUBSCRIPTION',
      'amount': amount,
      'currency': 'VND',
      'payment_method': 'NONE',
      'package_id': packageId,
      'description': 'Đăng ký gói $packageId',
    });
  }
}
