import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/billing/providers/payment_provider.dart';
import 'package:apphoctiengnnhat/features/billing/services/transaction_service.dart';

class _FakeTransactions implements TransactionService {
  final requests = <(String, int)>[];
  Object? failure;

  @override
  Future<void> createSubscriptionRequest({required String packageId, required int amount}) async {
    requests.add((packageId, amount));
    if (failure != null) throw failure!;
  }
}

void main() {
  late _FakeTransactions service;
  late PaymentProvider provider;

  setUp(() {
    service = _FakeTransactions();
    provider = PaymentProvider(service: service);
  });

  test('gói miễn phí là gói đang dùng nên không gửi được yêu cầu', () async {
    expect(provider.isFreePlanSelected, isTrue);
    expect(provider.canSubmit, isFalse);
    expect(await provider.submit(), isNotNull);
    expect(service.requests, isEmpty);
  });

  test('chọn gói trả phí rồi gửi: một yêu cầu đúng mã gói và số tiền', () async {
    provider.selectPlan('pro');
    expect(provider.canSubmit, isTrue);

    final pending = provider.submit();
    expect(provider.isSubmitting, isTrue);
    expect(provider.canSubmit, isFalse, reason: 'bấm hai lần không được gửi hai yêu cầu');

    expect(await pending, isNull);
    expect(provider.isSubmitting, isFalse);
    expect(service.requests, [('pro', provider.selectedPlan.amount)]);
  });

  test('gửi lỗi thì trả câu báo lỗi đọc được và cho gửi lại', () async {
    service.failure = ApiException('Máy chủ đang bận');
    provider.selectPlan('premium');

    expect(await provider.submit(), 'Máy chủ đang bận');
    expect(provider.canSubmit, isTrue);
  });
}
