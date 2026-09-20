import assert from 'node:assert/strict';
import test from 'node:test';

import { createAttemptSubmitter } from '../src/modules/streaks/attempt-submission.js';
import { createJlptSubmissionService } from '../src/modules/jlpt/jlpt-submission.service.js';
import { xpFor } from '../src/modules/streaks/streak-policy.js';

const USER = 'u1';
const EXAM = '507f1f77bcf86cd799439011';
const ATTEMPT = '11111111-2222-4333-8444-555555555555';
const OTHER_ATTEMPT = '99999999-8888-4777-8666-555555555555';

const EXAM_DOC = {
  _id: EXAM,
  is_published: true,
  is_active: true,
  pass_score: 90,
  time_limit: 105,
  sections: {},
};

/** Điểm do server chấm; test điều khiển qua hàm chấm giả. */
const scorerFor = (totalScore) => () => ({
  totalScore,
  sectionScores: { moji_goi: 10, bunpou: 10, dokkai: 10, choukai: totalScore - 30 },
  answerDetails: [
    { questionId: '507f1f77bcf86cd799439099', userChoice: 1, isCorrect: true, section: 'moji_goi', questionIndex: 0, groupIndex: 0 },
    { questionId: null, userChoice: 2, isCorrect: false, section: 'choukai', questionIndex: 1, groupIndex: 0 },
  ],
});

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
      events.set(key, { ...activity, session: options.session, receipt: activity.context?.receipt });
      return { xpAwarded: xpFor(activity.type, activity.context?.outcome), duplicate: false };
    },
  };
};

const fakeRepository = ({ exam = EXAM_DOC } = {}) => {
  const state = { saved: [], sessions: [] };
  return {
    state,
    async findExam(id, { session } = {}) {
      state.sessions.push(session);
      return exam;
    },
    async saveHistory(doc, { session } = {}) {
      state.sessions.push(session);
      state.saved.push(doc);
      return { _id: 'h1', ...doc };
    },
  };
};

const buildService = (repository, { totalScore = 120, journal = fakeJournal() } = {}) => {
  const service = createJlptSubmissionService({
    repository,
    submitter: createAttemptSubmitter({
      streak: journal,
      repository: journal,
      unitOfWork: { run: (fn) => fn({ session: 'sess' }) },
      clock: () => new Date('2026-09-19T03:00:00.000Z'),
    }),
    score: scorerFor(totalScore),
    now: () => new Date('2026-09-19T03:00:00.000Z'),
  });
  service.journal = journal;
  return service;
};

const submit = (service, { answers = [{ question_key: 'q1', selected: 1 }], attemptId = ATTEMPT, timeSpent = 3600 } = {}) =>
  service.submit({ userId: USER, examId: EXAM, attemptId, answers, timeSpent });

test('nộp đề lần đầu trả kết quả đã chấm và ghi 20 XP', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  const { result, replayed, xpAwarded } = await submit(service);

  assert.equal(replayed, false);
  assert.equal(result.TongDiemDatDuoc, 120);
  assert.equal(result.KetQuaCuoiCung, 'Đỗ');
  assert.equal(result.TongThoiGian, 3600);
  assert.equal(xpAwarded, 20);
  assert.equal(repository.state.saved.length, 1);
});

test('điểm dưới mức đạt trả Trượt, XP vẫn là 20 vì đã nộp hợp lệ', async () => {
  const service = buildService(fakeRepository(), { totalScore: 50 });
  const { result, xpAwarded } = await submit(service);

  assert.equal(result.KetQuaCuoiCung, 'Trượt');
  assert.equal(xpAwarded, 20);
});

test('gửi lại cùng attempt_id trả đúng kết quả lần đó, không ghi đè lịch sử', async () => {
  const repository = fakeRepository();
  const service = buildService(repository);

  const first = await submit(service);
  const retry = await submit(service);

  assert.equal(retry.replayed, true);
  assert.deepEqual(retry.result, first.result);
  assert.equal(retry.xpAwarded, 0);
  assert.equal(repository.state.saved.length, 1);
});

test('lần thi thứ hai điểm khác không làm hỏng kết quả retry của lần đầu', async () => {
  // `LearningHistory` chỉ giữ một bản ghi cho mỗi (user, đề), nên bản ghi đó
  // không định danh được một lần nộp. Receipt trong nhật ký mới là thứ giữ
  // đúng điểm của từng lượt (spec §3.3).
  const repository = fakeRepository();
  const service = buildService(repository);
  const first = await submit(service);

  service.scoreOverride = null;
  const second = await buildService(repository, {
    totalScore: 60,
    journal: service.journal,
  }).submit({ userId: USER, examId: EXAM, attemptId: OTHER_ATTEMPT, answers: [{ question_key: 'q1', selected: 2 }], timeSpent: 100 });
  assert.equal(second.result.TongDiemDatDuoc, 60);

  const replayFirst = await submit(service);
  assert.equal(replayFirst.result.TongDiemDatDuoc, first.result.TongDiemDatDuoc);
});

test('cùng attempt_id mà bài làm khác bị từ chối 409', async () => {
  const service = buildService(fakeRepository());
  await submit(service);

  await assert.rejects(
    submit(service, { answers: [{ question_key: 'q1', selected: 4 }] }),
    (error) => {
      assert.equal(error.status, 409);
      return true;
    },
  );
});

test('đề chưa xuất bản hoặc không tồn tại trả 404 và không ghi gì', async () => {
  const missing = buildService(fakeRepository({ exam: null }));
  await assert.rejects(submit(missing), (error) => {
    assert.equal(error.status, 404);
    return true;
  });
  assert.equal(missing.journal.events.size, 0);

  const unpublished = buildService(fakeRepository({ exam: { ...EXAM_DOC, is_published: false } }));
  await assert.rejects(submit(unpublished), (error) => {
    assert.equal(error.status, 404);
    return true;
  });
});

test('thiếu thời gian làm bài thì lấy trọn thời lượng đề', async () => {
  const service = buildService(fakeRepository());
  const { result } = await service.submit({
    userId: USER,
    examId: EXAM,
    attemptId: ATTEMPT,
    answers: [{ question_key: 'q1', selected: 1 }],
  });

  assert.equal(result.TongThoiGian, 105 * 60);
});
