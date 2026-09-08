import assert from 'node:assert/strict';
import test from 'node:test';

import Exercise from '../model/Exercise.js';
import {
  listByLesson,
  listByLevel,
  listByType,
} from '../src/modules/exercise/exercise.controller.js';

const LESSON_ID = '507f1f77bcf86cd799439011';

/** Một bài tập có đáp án đúng và lời giải, đúng như dữ liệu thật. */
const EXERCISE_ROW = () => ({
  _id: '507f1f77bcf86cd799439012',
  title: 'Bài tập N5',
  type: 'multiple_choice',
  level: 'N5',
  description: 'Chọn đáp án đúng',
  time_limit: 600,
  total_attempts: 3,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
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

/** Thay static của model bằng chain giả; khôi phục sau mỗi test. */
const stubExerciseFind = (rows) => {
  const original = Exercise.find;
  Exercise.find = () => ({
    select: () => ({ lean: async () => rows }),
  });
  return () => {
    Exercise.find = original;
  };
};

const captureJson = () => {
  const captured = {};
  const res = {
    status(code) {
      captured.status = code;
      return this;
    },
    json(payload) {
      captured.body = payload;
      return this;
    },
  };
  return { res, captured };
};

const HANDLERS = [
  ['listByLevel', listByLevel, { params: { level: 'N5' } }],
  ['listByType', listByType, { params: { type: 'multiple_choice' } }],
  ['listByLesson', listByLesson, { params: { lessonID: LESSON_ID } }],
];

for (const [name, handler, req] of HANDLERS) {
  test(`${name} không trả đáp án và lời giải`, async () => {
    const restore = stubExerciseFind([EXERCISE_ROW()]);

    try {
      const { res, captured } = captureJson();
      await handler(req, res);

      assert.equal(captured.status, undefined);
      assert.equal(captured.body.length, 1);

      const [exercise] = captured.body;
      // Kiểm tra theo trường, không dò chuỗi trên cả response.
      assert.equal('questions' in exercise, false);
      assert.equal('answers' in exercise, false);
      assert.equal('explanation' in exercise, false);
      assert.equal(exercise.question_count, 1);
      assert.equal(exercise.title, 'Bài tập N5');
      assert.equal(exercise.level, 'N5');
      assert.equal(exercise.time_limit, 600);
    } finally {
      restore();
    }
  });
}

test('bài tập không có câu hỏi vẫn trả question_count bằng 0', async () => {
  const row = EXERCISE_ROW();
  delete row.questions;
  const restore = stubExerciseFind([row]);

  try {
    const { res, captured } = captureJson();
    await listByLevel({ params: { level: 'N5' } }, res);

    assert.equal(captured.body[0].question_count, 0);
    assert.equal('questions' in captured.body[0], false);
  } finally {
    restore();
  }
});

test('danh sách rỗng trả về mảng rỗng, không phải 404', async () => {
  const restore = stubExerciseFind([]);

  try {
    const { res, captured } = captureJson();
    await listByType({ params: { type: 'listening' } }, res);

    assert.equal(captured.status, undefined);
    assert.deepEqual(captured.body, []);
  } finally {
    restore();
  }
});

test('listByLesson từ chối id sai định dạng trước khi truy vấn', async () => {
  let queried = false;
  const original = Exercise.find;
  Exercise.find = () => {
    queried = true;
    return { select: () => ({ lean: async () => [] }) };
  };

  try {
    const { res, captured } = captureJson();
    await listByLesson({ params: { lessonID: 'khong-phai-id' } }, res);

    assert.equal(captured.status, 400);
    assert.equal(queried, false);
  } finally {
    Exercise.find = original;
  }
});
