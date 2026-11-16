import assert from 'node:assert/strict';
import test from 'node:test';

import { createExerciseService } from '../src/modules/exercise/exercise.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const LESSON = '507f1f77bcf86cd799439011';

/** Một bài tập có đáp án đúng và lời giải, đúng như dữ liệu thật. */
const EXERCISE = () => ({
  _id: 'e1',
  title: 'Bài tập N5',
  type: 'Từ vựng',
  level: 'N5',
  time_limit: 10,
  questions: [
    {
      _id: 'q1',
      content: '「がくせい」の漢字は？',
      explanation: 'Đáp án là 学生',
      answers: [
        { _id: 'a1', content: '学生', is_correct: true },
        { _id: 'a2', content: '先生', is_correct: false },
      ],
    },
  ],
});

/** Kết quả đúng như bản lưu trong `ExerciseResult`, bài tập đã populate. */
const STORED_RESULT = {
  _id: 'r1',
  user_id: 'u1',
  exercise_id: { _id: 'e1', title: 'Bài tập N5', type: 'Từ vựng', level: 'N5' },
  score: 100,
  correct_count: 1,
  total_questions: 1,
  time_spent: 42,
  user_answers: [{ question_id: 'q1', answer_id: 'a1', is_correct: true, correct_answer_id: 'a1' }],
  is_passed: true,
  completed_at: new Date('2026-11-14T03:00:00.000Z'),
  createdAt: new Date('2026-11-14T03:00:01.000Z'),
};

const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      const result = results[name];
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

const build = (results) => {
  const fake = fakeRepository(results);
  return { ...fake, service: createExerciseService({ repository: fake.repository }) };
};

const isNotFound = (error) => error instanceof ApiError && error.status === 404;

test('danh sách theo cấp độ hay bài học chỉ đếm câu hỏi, không lộ đáp án và lời giải', async () => {
  const { calls, service } = build({ findActive: () => [EXERCISE(), { ...EXERCISE(), _id: 'e2', questions: undefined }] });

  const byLevel = await service.listByLevel('N5');
  await service.listByLesson(LESSON);

  assert.deepEqual(byLevel.map((item) => [item._id, item.question_count, 'questions' in item]), [
    ['e1', 1, false],
    ['e2', 0, false],
  ]);
  assert.deepEqual(calls, [['findActive', { level: 'N5' }], ['findActive', { lesson_id: LESSON }]]);
});

test('chi tiết để làm bài bỏ đáp án đúng và lời giải; bài không có hay đã tắt là 404', async () => {
  const { service } = build({ findActiveById: EXERCISE() });

  const exercise = await service.detail('e1');

  assert.deepEqual(exercise.questions, [{
    _id: 'q1',
    content: '「がくせい」の漢字は？',
    answers: [{ _id: 'a1', content: '学生' }, { _id: 'a2', content: '先生' }],
  }]);
  await assert.rejects(build({ findActiveById: null }).service.detail('e9'), isNotFound);
});

test('lịch sử là trang kết quả của chính mình, cùng hình dạng với kết quả vừa nộp', async () => {
  const { calls, service } = build({ findHistoryPage: [STORED_RESULT], countHistory: 21 });

  const page = await service.history({ userId: 'u1', page: 2, limit: 20 });

  assert.deepEqual(calls, [
    ['findHistoryPage', { userId: 'u1', skip: 20, limit: 20 }],
    ['countHistory', 'u1'],
  ]);
  assert.deepEqual({ ...page, items: undefined }, { items: undefined, total: 21, page: 2, limit: 20 });
  assert.deepEqual(page.items[0], {
    _id: 'r1',
    exercise_id: 'e1',
    exercise: { _id: 'e1', title: 'Bài tập N5', type: 'Từ vựng', level: 'N5' },
    score: 100,
    correct_answers: 1,
    total_questions: 1,
    time_spent: 42,
    passed: true,
    answers: STORED_RESULT.user_answers,
    createdAt: STORED_RESULT.createdAt,
  });
});

test('xem lại một kết quả kèm đề có đáp án và lời giải; của người khác là 404', async () => {
  const withQuestions = { ...STORED_RESULT, exercise_id: EXERCISE() };
  const { calls, service } = build({ findResult: withQuestions });

  const result = await service.result({ userId: 'u1', id: 'r1' });

  assert.equal(result.exercise.questions[0].explanation, 'Đáp án là 学生');
  assert.equal(result.exercise.questions[0].answers[0].is_correct, true);
  assert.deepEqual(calls, [['findResult', { id: 'r1', userId: 'u1' }]]);
  await assert.rejects(build({ findResult: null }).service.result({ userId: 'u2', id: 'r1' }), isNotFound);
});

test('bài tập đã bị xoá thì kết quả cũ vẫn xem được, chỉ thiếu phần đề', async () => {
  const { service } = build({ findResult: { ...STORED_RESULT, exercise_id: null } });

  const result = await service.result({ userId: 'u1', id: 'r1' });

  assert.equal(result.exercise_id, null);
  assert.equal(result.exercise, null);
});
