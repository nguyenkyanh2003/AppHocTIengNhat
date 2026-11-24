import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/jlpt/models/jlpt_models.dart';
import 'package:apphoctiengnnhat/features/jlpt/providers/jlpt_exam_provider.dart';
import 'package:apphoctiengnnhat/features/jlpt/providers/jlpt_provider.dart';
import 'package:apphoctiengnnhat/features/jlpt/services/jlpt_service.dart';

JLPTExamBrief _brief(String id) => JLPTExamBrief(id: id, title: 'Đề $id', level: 'N5');

const _question = JLPTQuestion(mondai: 1, questionText: 'A', choices: ['1', '2'], correctAnswer: 1);

JLPTExamDetail _exam(String id) => JLPTExamDetail(id: id, title: 'Đề $id', level: 'N5', timeLimit: 1, mojiGoi: const [_question]);

const _result = JLPTSubmitResult(totalScore: 120, vocabScore: 40, grammarScore: 30, readingScore: 30, listeningScore: 20, passed: true, duration: 30);

class _FakeService extends JLPTService {
  final calls = <String>[];
  Object? failure;
  Map<String, int>? submitted;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<Paged<JLPTExamBrief>> list({String? level, int? year, int? month, int page = 1, int limit = JLPTService.pageSize}) =>
      _answer('list $page ${level ?? '*'}', Paged(items: [_brief('p$page')], page: page, limit: limit, total: 2, totalPages: 2));

  @override
  Future<JLPTExamDetail> detail(String id) => _answer('detail $id', _exam(id));

  @override
  Future<JLPTSubmitResult> submit(String id, {required String attemptId, required Map<String, int> answers, required int timeSpent}) {
    submitted = answers;
    return _answer('submit $id', _result);
  }

  @override
  Future<List<JLPTQuestion>> solutions(String id) => _answer('solutions $id', const [_question]);
}

void main() {
  late _FakeService service;

  setUp(() => service = _FakeService());

  test('danh sách đề: lọc cấp độ tải lại từ trang đầu, cuộn thì tải thêm', () async {
    final provider = JLPTProvider(service: service);

    await provider.loadExams(level: 'N4');
    await provider.loadMore();

    expect(service.calls, ['list 1 N4', 'list 2 N4']);
    expect(provider.exams.valueOrNull?.map((exam) => exam.id), ['p1', 'p2']);
    expect(provider.level, 'N4');
  });

  group('một lượt thi', () {
    late JLPTExamProvider provider;

    setUp(() => provider = JLPTExamProvider(service: service));
    tearDown(() => provider.dispose());

    test('mở đề thì đặt đồng hồ theo thời lượng đề; lỗi tải hiện thành ViewFailure', () async {
      await provider.loadExam('e1');
      expect(provider.examOf('e1').valueOrNull?.title, 'Đề e1');
      expect(provider.secondsLeft, 60);

      service.failure = ApiException('Mất kết nối');
      await provider.loadExam('e2');
      expect(provider.examOf('e2').errorOrNull, 'Mất kết nối');
    });

    test('nộp bài gửi câu đã chọn, khoá bài làm và tải đáp án', () async {
      await provider.loadExam('e1');
      provider.setAnswer('moji-0', 1);

      expect(await provider.submit(), isNull);

      expect(service.submitted, {'moji-0': 1});
      expect((provider.hasSubmitted, provider.result?.totalScore), (true, 120));
      expect(provider.solutions.single.correctAnswer, 1);

      provider.setAnswer('moji-0', 0);
      expect(provider.answers['moji-0'], 1, reason: 'nộp rồi thì không đổi được bài làm');
    });

    test('chưa chọn đáp án nào: không gửi lên server, báo ngay vì sao chưa nộp', () async {
      await provider.loadExam('e1');

      expect(await provider.submit(), 'Bạn chưa chọn đáp án nào nên bài chưa được nộp.');
      expect(service.calls.where((call) => call.startsWith('submit')), isEmpty);
      expect(provider.hasSubmitted, isFalse);
    });

    test('nộp lỗi trả câu báo lỗi và cho nộp lại', () async {
      await provider.loadExam('e1');
      provider.setAnswer('moji-0', 1);
      service.failure = ApiException('Máy chủ đang bận');

      expect(await provider.submit(), 'Máy chủ đang bận');
      expect((provider.hasSubmitted, provider.isSubmitting), (false, false));
    });
  });
}
