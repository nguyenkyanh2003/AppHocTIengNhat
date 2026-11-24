import assert from 'node:assert/strict';
import test from 'node:test';

import { createAttemptSubmitter } from '../src/modules/streaks/attempt-submission.js';
import { createExerciseSubmissionService } from '../src/modules/exercise/exercise-submission.service.js';
import { rewardFor } from '../src/modules/streaks/streak-policy.js';

const USER = 'u1';
const EXERCISE = 'ex1';
const ATTEMPT = '11111111-2222-4333-8444-555555555555';

const QUESTIONS = [
  {
    _id: 'q1',
    answers: [
      { _id: 'a1', is_correct: true },
      { _id: 'a2', is_correct: false },
    ],
  },
  {
    _id: 'q2',
    answers: [
      { _id: 'b1', is_correct: true },
      { _id: 'b2', is_correct: false },
    ],
  },
];

const RIGHT = [
  { question_id: 'q1', answer_id: 'a1' },
  { question_id: 'q2', answer_id: 'b1' },
];
const WRONG = [
  { question_id: 'q1', answer_id: 'a2' },
  { question_id: 'q2', answer_id: 'b2' },
];

/**
 * Nhật ký giả: unique `(user, event_key)`, XP theo chính sách thật kể cả trần
 * theo bài, và XP lượt làm đóng dấu vào receipt — y như cổng ghi thật.
 */
const fakeJournal = () => {
  const events = new Map();
  const paid = new Map();
  return {
    events,
    async findEventByKey({ userId, eventKey }) {
      return events.get(`${userId}|${eventKey}`) ?? null;
    },
    async recordActivity(activity, options) {
      const key = `${activity.userId}|${activity.occurrenceKey}`;
      if (events.has(key)) return { xpAwarded: 0, xpRemaining: null, duplicate: true };
      const awardedBefore = paid.get(activity.sourceId) ?? 0;
      const { xp, remaining } = rewardFor(activity.type, activity.context?.outcome, { awardedBefore });
      paid.set(activity.sourceId, awardedBefore + xp);
      events.set(key, {
        ...activity,
        session: options.session,
        receipt: { ...activity.context?.receipt, xp: { awarded: xp, remaining } },
      });
      return { xpAwarded: xp, xpRemaining: remaining, duplicate: false };
    },
  };
};

const fakeRepository = ({ exercise = { _id: EXERCISE, questions: QUESTIONS, pass_score: 60 } } = {}) => {
  // `sessions`: lệnh trong transaction; `log`: thứ tự ghi so với lúc commit.
  const state = { results: [], attempts: 0, sessions: [], log: [] };
  return {
    state,
    async findExercise(id, { session } = {}) {
      state.sessions.push(session);
      return exercise;
    },
    async createResult(doc, { session } = {}) {
      state.sessions.push(session);
      const saved = { _id: `r${state.results.length + 1}`, createdAt: new Date('2026-09-19T03:00:00Z'), ...doc };
      state.results.push(saved);
      state.log.push(['result', session]);
      return saved;
    },
    async incrementAttempts(id, options) {
      state.log.push(['increment', options?.session]);
      state.attempts += 1;
    },
  };
};

const buildService = (repository, journal = fakeJournal()) => {
  const service = createExerciseSubmissionService({
    repository,
    submitter: createAttemptSubmitter({
      streak: journal,
      repository: journal,
      unitOfWork: {
        run: async (fn) => {
          const done = await fn({ session: 'sess' });
          repository.state.log.push(['commit']);
          return done;
        },
      },
      clock: () => new Date('2026-09-19T03:00:00.000Z'),
    }),
    now: () => new Date('2026-09-19T03:00:00.000Z'),
  });
  service.journal = journal;
  return service;
};

const submit = (service, { answers = RIGHT, attemptId = ATTEMPT, timeSpent = 42 } = {}) =>
  service.submit({ userId: USER, exerciseId: EXERCISE, attemptId, answers, timeSpent });

test('nộp bài lần đầu chấm điểm, lưu kết quả và ghi đúng một hoạt động', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  const { result, replayed, xpAwarded } = await submit(service);

  assert.equal(replayed, false);
  assert.equal(result.score, 100);
  assert.equal(result.correct_answers, 2);
  assert.equal(result.total_questions, 2);
  assert.equal(result.passed, true);
  assert.equal(result.time_spent, 42);
  assert.equal(repository.state.results.length, 1);
  assert.equal(repository.state.attempts, 1);
  // Bài đạt được 10 XP theo bảng chính sách.
  assert.equal(xpAwarded, 10);
  assert.equal(service.journal.events.size, 1);
});

test('bài chưa đạt vẫn được ghi nhận nhưng ít XP hơn', async () => {
  const service = buildService(fakeRepository());
  const { result, xpAwarded } = await submit(service, { answers: WRONG });

  assert.equal(result.passed, false);
  assert.equal(xpAwarded, 5);
});

test('client mất mạng rồi gửi lại: cùng kết quả, không cộng XP, không lưu thêm', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  const first = await submit(service);
  const retry = await submit(service);

  assert.equal(retry.replayed, true);
  assert.equal(retry.xpAwarded, 0);
  assert.deepEqual(retry.result, first.result);
  assert.equal(repository.state.results.length, 1, 'không được lưu kết quả lần hai');
  assert.equal(repository.state.attempts, 1, 'không được đếm thêm lượt làm');
});

test('gửi lại cùng attempt_id nhưng đổi đáp án bị từ chối 409', async () => {
  const service = buildService(fakeRepository());
  await submit(service);

  await assert.rejects(submit(service, { answers: WRONG }), (error) => {
    assert.equal(error.status, 409);
    assert.equal(error.code, 'ATTEMPT_PAYLOAD_MISMATCH');
    return true;
  });
});

test('lượt làm mới có attempt_id mới nên được chấm lại bình thường', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  await submit(service);
  const second = await submit(service, {
    attemptId: '99999999-8888-4777-8666-555555555555',
    answers: WRONG,
  });

  assert.equal(second.replayed, false);
  assert.equal(second.result.passed, false);
  assert.equal(repository.state.results.length, 2);
});

test('bài tập không tồn tại hoặc không có câu hỏi trả 404 và không ghi gì', async () => {
  const missing = buildService(fakeRepository({ exercise: null }));
  await assert.rejects(submit(missing), (error) => {
    assert.equal(error.status, 404);
    return true;
  });
  assert.equal(missing.journal.events.size, 0);

  const empty = buildService(fakeRepository({ exercise: { _id: EXERCISE, questions: [] } }));
  await assert.rejects(submit(empty), (error) => {
    assert.equal(error.status, 404);
    return true;
  });
});

test('mọi lệnh ghi của một lần nộp dùng chung một session', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);
  await submit(service);

  assert.deepEqual(new Set(repository.state.sessions), new Set(['sess']));
  assert.equal([...service.journal.events.values()][0].session, 'sess');
});

test('bộ đếm lượt làm tăng sau khi lượt nộp đã commit, ngoài transaction', async () => {
  // Mọi lượt nộp một bài, của mọi người học, đều ghi vào cùng document bài tập.
  // Tăng trong transaction thì cả lớp nộp cùng lúc sẽ xung đột ghi, hết lượt
  // thử lại và nhận 500 — đo được trên Atlas với 6 lượt nộp đồng thời.
  const repository = fakeRepository();
  await submit(buildService(repository));

  assert.deepEqual(repository.state.log, [['result', 'sess'], ['commit'], ['increment', undefined]]);
});

test('làm lại bài đã đạt bằng lượt mới: vẫn chấm và lưu, nhưng không cộng thêm XP', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  const first = await submit(service);
  const again = await submit(service, { attemptId: '99999999-8888-4777-8666-555555555555' });

  assert.deepEqual(first.result.xp, { awarded: 10, remaining: 0 });
  assert.equal(again.replayed, false);
  assert.equal(again.result.passed, true);
  assert.deepEqual(again.result.xp, { awarded: 0, remaining: 0 });
  assert.equal(repository.state.results.length, 2, 'lượt làm lại vẫn có kết quả để xem lại');
});

test('chưa đạt rồi làm đạt: lần sau nhận nốt phần XP còn thiếu', async () => {
  const service = buildService(fakeRepository());

  const failed = await submit(service, { answers: WRONG });
  const passed = await submit(service, { attemptId: '99999999-8888-4777-8666-555555555555' });

  assert.deepEqual(failed.result.xp, { awarded: 5, remaining: 5 });
  assert.deepEqual(passed.result.xp, { awarded: 5, remaining: 0 });
});
