import assert from 'node:assert/strict';
import test from 'node:test';

import { createAttemptSubmitter } from '../src/modules/streaks/attempt-submission.js';

const USER = 'u1';
const ATTEMPT = '11111111-2222-4333-8444-555555555555';
const SESSION = 'session-1';

/** Nhật ký giả: unique `(user, event_key)` y như index thật. */
const fakeJournal = () => {
  const events = new Map();
  return {
    events,
    async findEventByKey({ userId, eventKey }) {
      return events.get(`${userId}|${eventKey}`) ?? null;
    },
    async recordActivity(activity, options) {
      const key = `${activity.userId}|${activity.occurrenceKey}`;
      if (events.has(key)) return { xpAwarded: 0, duplicate: true };
      events.set(key, {
        user: activity.userId,
        event_key: activity.occurrenceKey,
        type: activity.type,
        receipt: activity.context?.receipt,
        session: options?.session,
      });
      return { xpAwarded: 10, duplicate: false };
    },
  };
};

const buildSubmitter = (journal, { unitOfWork } = {}) =>
  createAttemptSubmitter({
    streak: journal,
    repository: journal,
    unitOfWork: unitOfWork ?? { run: (fn) => fn({ session: SESSION }) },
    clock: () => new Date('2026-09-19T03:00:00.000Z'),
  });

const submitOnce = (submitter, { payload, persisted = [], result = { score: 8 } }) =>
  submitter.submit({
    userId: USER,
    type: 'exercise.submit',
    sourceId: 'ex1',
    attemptId: ATTEMPT,
    payload,
    persist: async ({ session }) => {
      persisted.push(session);
      return { result, outcome: { passed: true } };
    },
  });

test('lần nộp đầu tiên ghi kết quả và hoạt động trong cùng một session', async () => {
  const journal = fakeJournal();
  const persisted = [];
  const submitter = buildSubmitter(journal);

  const outcome = await submitOnce(submitter, { payload: { answers: [1, 2] }, persisted });

  assert.deepEqual(outcome.result, { score: 8 });
  assert.equal(outcome.replayed, false);
  assert.equal(outcome.xpAwarded, 10);
  assert.deepEqual(persisted, [SESSION]);
  assert.equal([...journal.events.values()][0].session, SESSION);
});

test('gửi lại cùng attempt_id và cùng bài làm trả đúng kết quả cũ, không chấm lại', async () => {
  const journal = fakeJournal();
  const persisted = [];
  const submitter = buildSubmitter(journal);
  const payload = { answers: [1, 2] };

  await submitOnce(submitter, { payload, persisted });
  const again = await submitOnce(submitter, { payload, persisted, result: { score: 999 } });

  assert.deepEqual(again.result, { score: 8 }, 'phải trả kết quả đã ghi, không phải lần chấm mới');
  assert.equal(again.replayed, true);
  assert.equal(again.xpAwarded, 0);
  assert.deepEqual(persisted, [SESSION], 'lần gửi lại không được ghi thêm kết quả');
});

test('thứ tự các khoá trong bài làm không làm nó thành một bài khác', async () => {
  const journal = fakeJournal();
  const submitter = buildSubmitter(journal);

  await submitOnce(submitter, { payload: { answers: [1], timeSpent: 30 } });
  const again = await submitOnce(submitter, { payload: { timeSpent: 30, answers: [1] } });

  assert.equal(again.replayed, true);
});

test('cùng attempt_id nhưng bài làm khác bị từ chối 409', async () => {
  const journal = fakeJournal();
  const submitter = buildSubmitter(journal);
  await submitOnce(submitter, { payload: { answers: [1, 2] } });

  await assert.rejects(
    submitOnce(submitter, { payload: { answers: [3, 4] } }),
    (error) => {
      assert.equal(error.status, 409);
      assert.equal(error.code, 'ATTEMPT_PAYLOAD_MISMATCH');
      return true;
    },
  );
});

test('hai request song song cùng attempt_id: một ghi, một nhận lại kết quả đã ghi', async () => {
  // Bên thua chạy hết transaction rồi mới đụng unique index. Kết quả nghiệp vụ
  // của nó phải bị rollback, và nó trả về kết quả của bên thắng.
  const journal = fakeJournal();
  const rolledBack = [];
  const unitOfWork = {
    run: async (fn) => {
      try {
        return await fn({ session: SESSION });
      } catch (error) {
        rolledBack.push(error);
        throw error;
      }
    },
  };
  const submitter = buildSubmitter(journal, { unitOfWork });
  const payload = { answers: [1, 2] };

  await submitOnce(submitter, { payload });
  // Nhật ký đã có event; mô phỏng bên thua bằng cách xoá bộ nhớ đệm đọc trước:
  // submitter phải tự xử lý trường hợp `recordActivity` báo trùng.
  const loser = await submitter.submit({
    userId: USER,
    type: 'exercise.submit',
    sourceId: 'ex1',
    attemptId: ATTEMPT,
    payload,
    persist: async () => ({ result: { score: 999 }, outcome: { passed: false } }),
  });

  assert.equal(loser.replayed, true);
  assert.deepEqual(loser.result, { score: 8 });
});

test('kết quả đã ghi mà thiếu receipt vẫn không bị chấm lại', async () => {
  // Event ghi bởi bản cũ (hoặc migration) không có receipt: không có gì để
  // đối chiếu, nhưng chắc chắn không được cộng XP lần hai.
  const journal = fakeJournal();
  journal.events.set(`${USER}|exercise.submit:${ATTEMPT}`, {
    user: USER,
    event_key: `exercise.submit:${ATTEMPT}`,
    type: 'exercise.submit',
  });
  const submitter = buildSubmitter(journal);

  await assert.rejects(
    submitOnce(submitter, { payload: { answers: [1] } }),
    (error) => {
      assert.equal(error.status, 409);
      return true;
    },
  );
});
