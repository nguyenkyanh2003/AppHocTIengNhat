import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/billing/services/transaction_service.dart';

void main() {
  test('gửi yêu cầu đăng ký gói: đúng loại, số tiền, mã gói; không tự đặt trạng thái', () async {
    late http.Request sent;
    await http.runWithClient(
      () => TransactionService().createSubscriptionRequest(packageId: 'pro', amount: 79000),
      () => MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({'data': {'_id': 't1', 'status': 'pending'}, 'message': 'Đã tạo yêu cầu giao dịch.'}),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/transactions/create'));
    expect(jsonDecode(sent.body), {
      'type': 'SUBSCRIPTION',
      'amount': 79000,
      'currency': 'VND',
      'payment_method': 'NONE',
      'package_id': 'pro',
      'description': 'Đăng ký gói pro',
    });
  });

  test('server từ chối thì ném lỗi để màn hiện câu báo', () async {
    await expectLater(
      http.runWithClient(
        () => TransactionService().createSubscriptionRequest(packageId: 'pro', amount: 79000),
        () => MockClient((_) async => http.Response(
              jsonEncode({'message': 'Dữ liệu gửi lên không hợp lệ.'}),
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
