import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/exercise/models/exercise.dart';
import 'package:apphoctiengnnhat/features/exercise/providers/exercise_provider.dart';
import 'package:apphoctiengnnhat/features/exercise/services/exercise_service.dart';

Exercise _exercise(String id) => Exercise(id: id, title: 'Bài $id', type: 'Từ vựng', level: 'N5');

ExerciseResult _result(String id) => ExerciseResult(
      id: id,
      exerciseId: 'e1',
      score: 100,
      correctAnswers: 1,
      totalQuestions: 1,
      timeSpent: 42,
      passed: true,
      createdAt: DateTime(2026, 11, 14),
    );

class _FakeService extends ExerciseService {
  final calls = <String>[];
  Object? failure;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<List<Exercise>> listAll() => _answer('all', [_exercise('e1')]);

  @override
  Future<List<Exercise>> listByLesson(String lessonId) => _answer('lesson $lessonId', <Exercise>[]);

  @override
  Future<Exercise> detail(String id) => _answer('detail $id', _exercise(id));

  @override
  Future<ExerciseResult> submit(String exerciseId,
          {required Map<String, String> answers, required int timeSpent, required String attemptId}) =>
      _answer('submit $exerciseId $attemptId ${answers.length}', _result('moi'));

  @override
  Future<Paged<ExerciseResult>> history({int page = 1, int limit = ExerciseService.pageSize}) =>
      _answer('history $page', Paged(items: [_result('r$page')], page: page, limit: limit, total: 2, totalPages: 2));

  @override
  Future<ExerciseResult> result(String id) => _answer('result $id', _result(id));
}

void main() {
  late _FakeService service;
  late ExerciseProvider provider;

  setUp(() {
    service = _FakeService();
    provider = ExerciseProvider(service: service);
  });

  test('tải mọi bài tập hoặc bài tập của một bài học qua ViewState; rỗng là data rỗng', () async {
    await provider.loadExercises();
    expect(provider.exercises.valueOrNull?.single.id, 'e1');

    await provider.loadExercises(lessonId: 'l1');
    expect(provider.exercises.valueOrNull, isEmpty);
    expect(service.calls, ['all', 'lesson l1']);
  });

  test('đề và kết quả tải theo id; mục khác còn sót coi như đang tải', () async {
    await provider.loadDetail('e1');
    await provider.loadResult('r1');

    expect(provider.detailOf('e1').valueOrNull?.title, 'Bài e1');
    expect(provider.detailOf('e2').isLoading, isTrue);
    expect(provider.resultOf('r1').valueOrNull?.id, 'r1');
  });

  test('nộp bài trả kết quả để màn chuyển trang; lỗi trả câu báo, cho nộp lại', () async {
    final submitted = await provider.submit('e1', answers: {'q1': 'a1'}, timeSpent: 42, attemptId: 'attempt-1');
    expect(submitted.valueOrNull?.id, 'moi');
    expect(provider.isSubmitting, isFalse);

    service.failure = ApiException('Mất kết nối');
    final failed = await provider.submit('e1', answers: {'q1': 'a1'}, timeSpent: 42, attemptId: 'attempt-1');
    expect(failed.errorOrNull, 'Mất kết nối');
    expect(service.calls.where((call) => call == 'submit e1 attempt-1 1'), hasLength(2));
  });

  test('chưa trả lời câu nào: không gửi lên server, báo ngay vì sao chưa nộp', () async {
    final submitted = await provider.submit('e1', answers: const {}, timeSpent: 42, attemptId: 'attempt-1');

    expect(submitted.errorOrNull, 'Bạn chưa trả lời câu nào nên bài chưa được nộp.');
    expect(service.calls, isEmpty, reason: 'server không nhận bài nộp rỗng');
    expect(provider.isSubmitting, isFalse);
  });

  test('lịch sử phân trang, tải thêm nối vào; lỗi hiện thành ViewFailure', () async {
    await provider.loadHistory();
    await provider.loadMore();
    expect(provider.history.valueOrNull?.map((result) => result.id), ['r1', 'r2']);

    service.failure = ApiException('Mất kết nối');
    await provider.loadHistory();
    expect(provider.history.errorOrNull, 'Mất kết nối');
  });

  test('đăng xuất xoá sạch', () async {
    await provider.loadExercises();
    await provider.loadDetail('e1');

    provider.clear();

    expect(provider.exercises, isA<ViewIdle<List<Exercise>>>());
    expect(provider.detailOf('e1').isLoading, isTrue);
  });
}
