import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_dashboard_summary.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_report.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_report_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/jlpt/models/jlpt_practice_question.dart';
import 'package:apphoctiengnnhat/features/jlpt/providers/jlpt_practice_provider.dart';
import 'package:apphoctiengnnhat/features/jlpt/services/jlpt_service.dart';

class _FakeAdminService extends AdminService {
  final calls = <List<String?>>[];
  Object? respondError;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> reportRows = const [];

  @override
  Future<AdminDashboardSummary> dashboard() async => AdminDashboardSummary.fromStats(stats);

  /// Lọc theo loại như server: màn không tự lọc trên trang đã tải.
  @override
  Future<Paged<AdminReport>> reports({int page = 1, String? status, String? type}) async {
    final rows = [for (final row in reportRows) if (type == null || row['type'] == type) AdminReport.fromJson(row)];
    return Paged(items: rows, page: 1, limit: 20, total: rows.length, totalPages: 1);
  }

  @override
  Future<AdminReportStats> reportStats() async =>
      const AdminReportStats(total: 0, pending: 0, inProgress: 0, resolved: 0);

  @override
  Future<void> updateReport(String id, {required String status, String? response}) async {
    if (respondError != null) throw respondError!;
    calls.add([id, response, status]);
  }
}

class _FakeJlptService extends JLPTService {
  Object? error;
  List<Map<String, dynamic>> items = const [];

  @override
  Future<List<JlptPracticeQuestion>> practice({required String type, String? level, int limit = 10}) async {
    if (error != null) throw error!;
    return items.map(JlptPracticeQuestion.fromJson).toList();
  }
}

Map<String, dynamic> _report(String id,
        {String type = 'bug', String status = 'pending'}) =>
    {
      '_id': id,
      'title': 'Báo cáo $id',
      'description': 'Nội dung $id',
      'type': type,
      'status': status,
      'priority': 'low',
      'createdAt': '2026-11-05T07:00:00.000Z',
    };

Widget _adminApp(Widget screen) => MaterialApp(theme: AppTheme.lightTheme, home: screen);

void main() {
  group('tổng quan quản trị', () {
    test('đọc đúng số từ các API thống kê', () {
      final summary = AdminDashboardSummary.fromStats({
        'users': {
          'totalUsers': 9,
          'recentUsers': [
            {'HoTen': 'Lan', 'NgayTao': '2026-11-05T07:00:00.000Z'},
          ],
        },
        'lessons': {'totalLessons': 40},
        'reports': {
          'byStatus': [
            {'_id': 'resolved', 'count': 3},
            {'_id': 'pending', 'count': 2},
          ],
          'recentReports': [
            {'title': 'Sai nghĩa', 'createdAt': '2026-11-05T08:00:00.000Z'},
          ],
        },
        'analytics': {
          'metrics': {'active_today': 4},
        },
      });

      expect(summary.totalUsers, 9);
      expect(summary.totalLessons, 40);
      expect(summary.pendingReports, 2);
      expect(summary.activeToday, 4);
      expect(summary.activities.map((a) => a.subtitle), ['Sai nghĩa', 'Lan']);
    });

    test('thiếu dữ liệu thì là 0, không phải số mẫu', () {
      final summary = AdminDashboardSummary.fromStats(const {});

      expect(summary.totalUsers, 0);
      expect(summary.pendingReports, 0);
      expect(summary.activities, isEmpty);
    });

    testWidgets('màn hình không còn số và hoạt động giả', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _FakeAdminService()
        ..stats = {
          'users': {'totalUsers': 77},
          'lessons': {'totalLessons': 40},
        };

      await tester.pumpWidget(_adminApp(AdminDashboardScreen(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('77'), findsOneWidget);
      for (final fake in [
        '15234',
        '2450',
        '342',
        '89.5%',
        'nguyenvana@example.com',
        'Hoạt động bình thường'
      ]) {
        expect(find.textContaining(fake), findsNothing,
            reason: 'Còn dữ liệu giả: $fake');
      }
      expect(find.text('Chưa có hoạt động nào.'), findsOneWidget);
    });
  });

  group('quản trị báo cáo', () {
    Future<_FakeAdminService> pumpReports(
        WidgetTester tester, List<Map<String, dynamic>> reports) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _FakeAdminService()..reportRows = reports;
      await tester.pumpWidget(_adminApp(AdminReportManagementScreen(service: service)));
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('gửi phản hồi thì lưu lên server', (tester) async {
      final service = await pumpReports(tester, [_report('r1')]);

      await tester.tap(find.text('Báo cáo r1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phản hồi').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Đã sửa xong');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gửi'));
      await tester.pumpAndSettle();

      expect(service.calls, [
        ['r1', 'Đã sửa xong', 'in_progress'],
      ]);
      expect(find.text('Đã gửi phản hồi.'), findsOneWidget);
    });

    testWidgets('lọc theo loại chỉ còn báo cáo của loại đó', (tester) async {
      await pumpReports(
          tester, [_report('r1'), _report('r2', type: 'content')]);
      expect(find.text('Báo cáo r1'), findsOneWidget);

      await tester.tap(find.byTooltip('Lọc theo loại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nội dung').last);
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo r1'), findsNothing);
      expect(find.text('Báo cáo r2'), findsOneWidget);
    });
  });

  group('luyện nhanh JLPT', () {
    final question = {
      'question_text': 'Câu hỏi',
      'choices': ['A', 'B'],
      'correct_answer': 1,
      'explanation': 'Vì B',
    };

    test('model đọc đáp án đúng và lời giải', () {
      final parsed = JlptPracticeQuestion.fromJson(question);

      expect(parsed.correctAnswer, 1);
      expect(parsed.choices, ['A', 'B']);
      expect(parsed.explanation, 'Vì B');
    });

    test('chấm đúng sai và không cho đổi câu đã trả lời', () async {
      final provider = JLPTPracticeProvider(
          service: _FakeJlptService()..items = [question, question]);
      await provider.loadPractice(type: 'moji_goi');

      provider.answer(0, 1);
      provider.answer(1, 0);
      provider.answer(1, 1);

      expect(provider.answeredCount, 2);
      expect(provider.correctCount, 1);
      expect(provider.answerOf(1), 0);
    });

    test('chưa có câu nào phù hợp là danh sách rỗng, không phải lỗi', () async {
      final provider = JLPTPracticeProvider(service: _FakeJlptService());

      await provider.loadPractice(type: 'choukai');

      expect(provider.questions.valueOrNull, isEmpty);
    });

    test('lỗi mạng thì báo lỗi', () async {
      final provider = JLPTPracticeProvider(
          service: _FakeJlptService()..error = NetworkException('Mất mạng'));

      await provider.loadPractice(type: 'choukai');

      expect(provider.questions.errorOrNull, 'Mất mạng');
    });

    test('tải bộ mới thì xoá câu trả lời cũ', () async {
      final provider =
          JLPTPracticeProvider(service: _FakeJlptService()..items = [question]);
      await provider.loadPractice(type: 'moji_goi');
      provider.answer(0, 1);

      await provider.loadPractice(type: 'moji_goi');

      expect(provider.answeredCount, 0);
    });
  });
}
