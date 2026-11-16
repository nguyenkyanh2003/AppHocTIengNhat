import assert from 'node:assert/strict';
import test from 'node:test';

import { createJlptService } from '../src/modules/jlpt/jlpt.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const EXAM_ID = '507f1f77bcf86cd799439011';

/** Một đề đủ bốn phần, câu nào cũng có đáp án và lời giải như dữ liệu thật. */
const EXAM = () => ({
  _id: EXAM_ID,
  title: 'N5 tháng 7/2026',
  level: 'N5',
  year: 2026,
  month: 7,
  time_limit: 105,
  pass_score: 80,
  total_score: 180,
  total_views: 9,
  createdAt: new Date('2026-07-01T00:00:00.000Z'),
  sections: {
    moji_goi: [{ question_text: 'A', choices: ['1', '2'], correct_answer: 0, explanation: 'vì A' }],
    bunpou: [{ question_text: 'B', choices: ['1', '2'], correct_answer: 1, explanation: 'vì B' }],
    dokkai: [{ group_content: 'Đoạn văn', questions: [{ question_text: 'C', correct_answer: 0 }, { question_text: 'D', correct_answer: 1 }] }],
    choukai: [{ group_audio: '/audio/1.mp3', transcript: 'lời thoại', questions: [{ question_text: 'E', correct_answer: 1, explanation: 'vì E' }] }],
  },
});

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
  return { ...fake, service: createJlptService({ repository: fake.repository, shuffle: (items) => items }) };
};

const rejectsWith = (status) => (error) => error instanceof ApiError && error.status === status;

test('danh sách đề kèm số câu và kết quả gần nhất của người đang xem', async () => {
  const { calls, service } = build({
    findPublishedPage: [EXAM(), { ...EXAM(), _id: 'e2', sections: {} }],
    countPublished: 12,
    findLatestResults: [{ exam: EXAM_ID, score: 120, is_passed: true, taken_at: new Date('2026-11-14T03:00:00.000Z') }],
  });

  const page = await service.list({ userId: 'u1', page: 2, limit: 10, level: 'N5', year: 2026 });

  assert.deepEqual(calls.slice(0, 2), [
    ['findPublishedPage', { filter: { level: 'N5', year: 2026 }, skip: 10, limit: 10 }],
    ['countPublished', { level: 'N5', year: 2026 }],
  ]);
  assert.deepEqual(calls[2], ['findLatestResults', { userId: 'u1', examIds: [EXAM_ID, 'e2'] }]);
  assert.equal(page.total, 12);
  assert.equal(page.items[0].total_questions, 5);
  assert.deepEqual(page.items[0].last_result, { score: 120, is_passed: true, completed_at: new Date('2026-11-14T03:00:00.000Z') });
  assert.equal(page.items[1].last_result, null);
  assert.equal('sections' in page.items[0], false);
});

test('đề để thi bỏ đáp án và lời giải ở cả câu lẻ lẫn câu trong nhóm; đề không có là 404', async () => {
  const { calls, service } = build({ findPublishedAndCountView: EXAM() });

  const exam = await service.detail(EXAM_ID);

  assert.deepEqual(calls, [['findPublishedAndCountView', EXAM_ID]]);
  assert.deepEqual(exam.sections.moji_goi, [{ question_text: 'A', choices: ['1', '2'] }]);
  assert.deepEqual(exam.sections.dokkai[0], { group_content: 'Đoạn văn', questions: [{ question_text: 'C' }, { question_text: 'D' }] });
  assert.equal(exam.sections.choukai[0].transcript, 'lời thoại');
  assert.equal(JSON.stringify(exam).includes('correct_answer'), false);
  await assert.rejects(build({ findPublishedAndCountView: null }).service.detail(EXAM_ID), rejectsWith(404));
});

test('đáp án chỉ mở sau khi đã nộp đề: chưa nộp 403, đề không có 404', async () => {
  const { service } = build({ hasResult: true, findPublished: EXAM() });
  const solutions = await service.solutions({ userId: 'u1', examId: EXAM_ID });
  assert.equal(solutions.sections.moji_goi[0].explanation, 'vì A');

  await assert.rejects(build({ hasResult: false }).service.solutions({ userId: 'u1', examId: EXAM_ID }), rejectsWith(403));
  await assert.rejects(
    build({ hasResult: true, findPublished: null }).service.solutions({ userId: 'u1', examId: EXAM_ID }),
    rejectsWith(404),
  );
});

test('luyện nhanh rút câu theo kỹ năng, câu nhóm mang theo đoạn văn/âm thanh; không có câu là danh sách rỗng', async () => {
  const { calls, service } = build({ findPracticeSections: [EXAM()] });

  const listening = await service.practice({ type: 'choukai', level: 'N5', limit: 10 });
  const vocabulary = await service.practice({ type: 'moji_goi', limit: 1 });

  assert.deepEqual(calls[0], ['findPracticeSections', { type: 'choukai', level: 'N5' }]);
  assert.deepEqual(listening, [{
    question_text: 'E',
    correct_answer: 1,
    explanation: 'vì E',
    group_content: undefined,
    group_image: undefined,
    group_audio: '/audio/1.mp3',
    transcript: 'lời thoại',
    exam_id: EXAM_ID,
    exam_title: 'N5 tháng 7/2026',
    level: 'N5',
    section: 'choukai',
  }]);
  assert.equal(vocabulary.length, 1);

  assert.deepEqual(await build({ findPracticeSections: [] }).service.practice({ type: 'bunpou', limit: 10 }), []);
});
