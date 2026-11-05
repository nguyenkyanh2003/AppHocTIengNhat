import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/progress/models/dashboard.dart';
import 'package:apphoctiengnnhat/features/progress/models/timeline_chart.dart';
import 'package:apphoctiengnnhat/features/progress/models/xp_activity.dart';
import 'package:apphoctiengnnhat/features/progress/providers/progress_provider.dart';
import 'package:apphoctiengnnhat/features/progress/services/progress_service.dart';

DashboardStats _stats({int vocabulary = 3}) =>
    DashboardStats.fromJson({'vocabulary_learned': vocabulary});

TimelineData _day(String date,
        {int xp = 10, int seconds = 60, int exercises = 1, int lessons = 1}) =>
    TimelineData(
        date: date,
        exercises: exercises,
        lessons: lessons,
        time: seconds,
        xp: xp);

class _FakeService extends ProgressService {
  _FakeService();

  Object? statsError;
  Object? timelineError;
  Map<String, Completer<List<TimelineData>>> pendingTimelines = {};
  List<TimelineData> timeline = [];
  int vocabulary = 3;

  @override
  Future<DashboardStats> getDashboardStats() async {
    if (statsError != null) throw statsError!;
    return _stats(vocabulary: vocabulary);
  }

  @override
  Future<List<TimelineData>> getTimeline({String period = 'week'}) async {
    if (timelineError != null) throw timelineError!;
    final pending = pendingTimelines[period];
    if (pending != null) return pending.future;
    return timeline;
  }

  @override
  Future<List<HeatmapData>> getHeatmap({int? year}) async => const [];

  @override
  Future<DashboardBreakdown> getBreakdown() async =>
      DashboardBreakdown(lessonsByLevel: const [], exercisesByType: const []);
}

void main() {
  group('tải dữ liệu', () {
    test('thành công thì có dữ liệu', () async {
      final provider = ProgressProvider(service: _FakeService());
      expect(provider.dashboard, isA<ViewIdle<ProgressDashboard>>());

      await provider.loadDashboardData();

      expect(provider.dashboard.valueOrNull?.stats.vocabularyLearned, 3);
      expect(provider.stats?.vocabularyLearned, 3);
    });

    test('lỗi mạng thì báo lỗi, không coi là chưa có dữ liệu', () async {
      final provider = ProgressProvider(
          service: _FakeService()..statsError = NetworkException('Mất mạng'));

      await provider.loadDashboardData();

      expect(provider.dashboard.errorOrNull, 'Mất mạng');
    });

    test('lỗi lạ không lộ chi tiết kỹ thuật', () async {
      final provider = ProgressProvider(
          service: _FakeService()..statsError = StateError('hỏng'));

      await provider.loadDashboardData();

      expect(provider.dashboard.errorOrNull, isNot(contains('hỏng')));
    });

    test('tải lại hỏng thì giữ số liệu đang có', () async {
      final service = _FakeService();
      final provider = ProgressProvider(service: service);
      await provider.loadDashboardData();

      service.statsError = NetworkException('Mất mạng');
      await provider.loadDashboardData();

      expect(provider.dashboard.valueOrNull?.stats.vocabularyLearned, 3);
    });

    test('đang tải lại vẫn giữ số liệu cũ trên màn', () async {
      final service = _FakeService();
      final provider = ProgressProvider(service: service);
      await provider.loadDashboardData();

      final states = <bool>[];
      provider.addListener(() => states.add(provider.dashboard.hasData));
      await provider.loadDashboardData();

      expect(states, everyElement(isTrue));
    });

    test('đăng xuất xoá sạch dữ liệu', () async {
      final provider = ProgressProvider(service: _FakeService());
      await provider.loadDashboardData();

      provider.clear();

      expect(provider.dashboard, isA<ViewIdle<ProgressDashboard>>());
      expect(provider.selectedPeriod, 'week');
    });
  });

  group('đổi kỳ', () {
    test('thành công thì đổi kỳ và thay biểu đồ', () async {
      final service = _FakeService();
      final provider = ProgressProvider(service: service);
      await provider.loadDashboardData();

      service.timeline = [_day('2026-11-05')];
      expect(await provider.changePeriod('month'), isNull);

      expect(provider.selectedPeriod, 'month');
      expect(provider.timeline, hasLength(1));
    });

    test('lỗi thì trả câu báo lỗi, giữ nguyên kỳ cũ và số liệu cũ', () async {
      final service = _FakeService();
      service.timeline = [_day('2026-11-05')];
      final provider = ProgressProvider(service: service);
      await provider.loadDashboardData();

      service.timelineError = NetworkException('Mất mạng');
      expect(await provider.changePeriod('year'), 'Mất mạng');

      expect(provider.selectedPeriod, 'week');
      expect(provider.timeline, hasLength(1));
    });

    test('bấm nhanh hai kỳ: phản hồi về muộn của kỳ trước không đè kỳ sau',
        () async {
      final service = _FakeService();
      final provider = ProgressProvider(service: service);
      await provider.loadDashboardData();

      final month = service.pendingTimelines['month'] = Completer();
      final year = service.pendingTimelines['year'] = Completer();
      final first = provider.changePeriod('month');
      final second = provider.changePeriod('year');
      year.complete([_day('2026-01-01')]);
      await second;
      month.complete([_day('2026-10-01'), _day('2026-10-02')]);
      await first;

      expect(provider.selectedPeriod, 'year');
      expect(provider.timeline, hasLength(1));
    });
  });

  group('tổng hợp theo kỳ', () {
    test('cộng XP, bài học, bài tập và thời gian', () {
      final summary = TimelineSummary.of([
        _day('2026-11-04', xp: 20, seconds: 120),
        _day('2026-11-05', xp: 5, seconds: 30)
      ]);

      expect(summary.xp, 25);
      expect(summary.exercises, 2);
      expect(summary.lessons, 2);
      expect(summary.seconds, 150);
    });

    test('định dạng thời gian theo giờ và phút', () {
      expect(formatStudySeconds(0), '0 phút');
      expect(formatStudySeconds(90 * 60), '1 giờ 30 phút');
    });
  });

  group('cột biểu đồ', () {
    final now = DateTime(2026, 11, 5); // thứ Năm

    test('tuần: đủ 7 ngày tính cả hôm nay, ngày không học là 0', () {
      final bars = chartBars(
          [_day('2026-11-05', xp: 30), _day('2026-10-30', xp: 10)],
          period: 'week', now: now);

      expect(bars, hasLength(7));
      expect(bars.first.label, 'T6');
      expect(bars.first.xp, 10);
      expect(bars.last.label, 'T5');
      expect(bars.last.xp, 30);
      expect(bars[1].xp, 0);
    });

    test('tháng: 30 cột, chỉ ghi nhãn thưa để không chồng chữ', () {
      final bars =
          chartBars([_day('2026-11-05', xp: 7)], period: 'month', now: now);

      expect(bars, hasLength(30));
      expect(bars.last.xp, 7);
      expect(bars.where((bar) => bar.label.isNotEmpty).length,
          lessThanOrEqualTo(6));
    });

    test('năm: gộp theo tháng, 12 cột', () {
      final bars = chartBars([
        _day('2026-11-05', xp: 7),
        _day('2026-11-01', xp: 3),
        _day('2026-01-02', xp: 5)
      ], period: 'year', now: now);

      expect(bars, hasLength(12));
      expect(bars.last.label, 'T11');
      expect(bars.last.xp, 10);
      expect(bars.singleWhere((bar) => bar.label == 'T1').xp, 5);
    });
  });

  group('phân loại hoạt động XP', () {
    test('đúng các nhãn server gửi', () {
      expect(xpActivityKindOf('Học mục trong bài'), XpActivityKind.lesson);
      expect(xpActivityKindOf('Hoàn thành bài học'), XpActivityKind.lesson);
      expect(xpActivityKindOf('Làm bài tập'), XpActivityKind.exercise);
      expect(xpActivityKindOf('Làm đề JLPT'), XpActivityKind.exercise);
      expect(xpActivityKindOf('Ôn tập SRS'), XpActivityKind.review);
      expect(xpActivityKindOf('Thưởng mốc chuỗi ngày'), XpActivityKind.reward);
      expect(xpActivityKindOf('Mở khoá thành tích'), XpActivityKind.reward);
    });

    test('nhãn lạ từ dữ liệu cũ vẫn hiện ở mục khác', () {
      expect(xpActivityKindOf('abc'), XpActivityKind.other);
    });
  });
}
