import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/reports/models/report.dart';
import 'package:apphoctiengnnhat/features/reports/providers/report_provider.dart';
import 'package:apphoctiengnnhat/features/reports/services/report_service.dart';

Report _report(String id) => Report(id: id, type: 'bug', title: 'Báo cáo $id', description: '...', createdAt: DateTime(2026, 11, 14));

class _FakeService implements ReportService {
  final created = <String>[];
  var listed = 0;
  Object? createFailure;

  @override
  Future<Report> create({
    required String type,
    required String title,
    required String description,
    String? relatedId,
    String? relatedType,
    String priority = 'medium',
  }) async {
    if (createFailure != null) throw createFailure!;
    created.add(title);
    return _report('moi');
  }

  @override
  Future<Paged<Report>> listMine({int page = 1, int limit = ReportService.pageSize, String? status}) async {
    listed++;
    return Paged(items: [_report('r$listed')], page: 1, limit: limit, total: 1, totalPages: 1);
  }
}

void main() {
  late _FakeService service;
  late ReportProvider provider;

  setUp(() {
    service = _FakeService();
    provider = ReportProvider(service: service);
  });

  test('tải báo cáo của tôi qua ViewState', () async {
    await provider.loadMyReports();
    expect(provider.myReports.valueOrNull?.single.id, 'r1');
  });

  test('gửi thành công trả null và làm mới danh sách đã mở', () async {
    await provider.loadMyReports();

    final pending = provider.createReport(type: 'bug', title: 'Lỗi', description: 'Không mở được bài');
    expect(provider.isSubmitting, isTrue);
    expect(await pending, isNull);

    expect(provider.isSubmitting, isFalse);
    expect(service.created, ['Lỗi']);
    await Future<void>.delayed(Duration.zero);
    expect(service.listed, 2, reason: 'báo cáo vừa gửi phải hiện trong "Báo cáo của tôi"');
  });

  test('gửi lỗi trả câu báo đọc được, không đụng danh sách', () async {
    service.createFailure = ApiException('Tiêu đề quá dài');

    expect(await provider.createReport(type: 'bug', title: 'x', description: 'y'), 'Tiêu đề quá dài');
    expect(provider.isSubmitting, isFalse);
    expect(service.listed, 0);
  });
}
