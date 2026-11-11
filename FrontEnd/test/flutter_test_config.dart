import 'dart:async';

// `httpClient` chỉ mở qua src cho test; gói không có cách công khai để thay nó.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Dựng theme là tải font qua mạng, và không ai chờ lần tải đó.
///
/// Test bị chặn mạng nên lần tải hỏng, và lỗi bay vào test nào đang chạy lúc nó về:
/// `test()` thường chỉ đỏ khi lỗi về kịp, nên đỏ thất thường. Cho lần tải treo mãi:
/// không có mạng, không có lỗi, chữ vẫn dùng font của test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  google_fonts.httpClient = MockClient(
    (_) => Completer<http.Response>().future,
  );
  await testMain();
}
