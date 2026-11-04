import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import ExerciseResult from '../model/ExerciseResult.js';
import LearningHistory from '../model/LearningHistory.js';
import Lesson from '../model/Lesson.js';
import LessonProgress from '../model/LessonProgress.js';
import User from '../model/User.js';
import { createProgressRepository } from '../src/modules/progress/progress.repository.js';

const USER_ID = '64b7f0c2a1b2c3d4e5f60700';
const FROM = new Date('2026-10-28T17:00:00.000Z');
const TO = new Date('2026-11-04T17:00:00.000Z');

/**
 * Model giả ghi lại lệnh **cùng đối số**: lỗi của tầng này là sai tên trường
 * hoặc quên ép kiểu, mà Mongoose không báo — truy vấn chỉ lặng lẽ ra rỗng.
 */
const fakeModel = ({ rows = [], collectionName = 'fakes' } = {}) => {
  const calls = [];
  const chain = {
    select: (arg) => (calls.push(['select', arg]), chain),
    lean: async () => rows,
  };
  return {
    calls,
    collection: { name: collectionName },
    find: (filter) => (calls.push(['find', filter]), chain),
    countDocuments: async (filter) => (calls.push(['countDocuments', filter]), 4),
    aggregate: async (pipeline) => (calls.push(['aggregate', pipeline]), rows),
  };
};

const repositoryWith = (models) =>
  createProgressRepository({
    ExerciseResult: fakeModel(),
    Exercise: fakeModel({ collectionName: 'exercises' }),
    LessonProgress: fakeModel(),
    Lesson: fakeModel({ collectionName: 'lessons' }),
    LearningHistory: fakeModel(),
    User: fakeModel(),
    ...models,
  });

const matchOf = (model) => model.calls[0][1][0].$match;

test('phép gộp theo user ép id chuỗi sang ObjectId — aggregate không tự ép kiểu như find', async () => {
  const results = fakeModel({ rows: [{ _id: null, seconds: 900 }] });
  const progress = fakeModel();
  const repository = repositoryWith({ ExerciseResult: results, LessonProgress: progress });

  assert.equal(await repository.sumExerciseSeconds(USER_ID), 900);
  await repository.lessonsByLevel(USER_ID);

  assert.ok(matchOf(results).user_id instanceof mongoose.Types.ObjectId);
  assert.equal(String(matchOf(results).user_id), USER_ID);
  assert.ok(matchOf(progress).user instanceof mongoose.Types.ObjectId);
});

test('chưa làm bài tập nào thì tổng thời gian là 0', async () => {
  assert.equal(await repositoryWith({}).sumExerciseSeconds(USER_ID), 0);
});

test('thống kê bài tập theo loại đếm số lần đạt bằng is_passed', async () => {
  const results = fakeModel();

  await repositoryWith({ ExerciseResult: results }).exercisesByType(USER_ID);

  const [, pipeline] = results.calls[0];
  assert.deepEqual(pipeline.slice(1), [
    {
      $lookup: { from: 'exercises', localField: 'exercise_id', foreignField: '_id', as: 'exercise' },
    },
    { $unwind: '$exercise' },
    {
      $group: {
        _id: '$exercise.type',
        count: { $sum: 1 },
        average_score: { $avg: '$score' },
        passed: { $sum: { $cond: ['$is_passed', 1, 0] } },
      },
    },
    { $sort: { _id: 1 } },
  ]);
});

test('bài học theo cấp độ nối sang Lesson.level, N5 đứng trước', async () => {
  const progress = fakeModel();

  await repositoryWith({ LessonProgress: progress }).lessonsByLevel(USER_ID);

  const [, pipeline] = progress.calls[0];
  assert.deepEqual(pipeline.slice(1), [
    { $lookup: { from: 'lessons', localField: 'lesson', foreignField: '_id', as: 'lesson' } },
    { $unwind: '$lesson' },
    {
      $group: {
        _id: '$lesson.level',
        completed: { $sum: { $cond: ['$is_completed', 1, 0] } },
        in_progress: { $sum: { $cond: ['$is_completed', 0, 1] } },
      },
    },
    { $sort: { _id: -1 } },
  ]);
});

test('hoạt động trong khoảng lọc theo mốc hoàn thành bài tập và lần học bài gần nhất', async () => {
  const results = fakeModel();
  const progress = fakeModel();
  const repository = repositoryWith({ ExerciseResult: results, LessonProgress: progress });

  await repository.findExerciseResultsBetween({ userId: USER_ID, from: FROM, to: TO });
  await repository.findLessonsStudiedBetween({ userId: USER_ID, from: FROM, to: TO });

  assert.deepEqual(results.calls, [
    ['find', { user_id: USER_ID, completed_at: { $gte: FROM, $lt: TO } }],
    ['select', 'completed_at time_spent'],
  ]);
  assert.deepEqual(progress.calls, [
    ['find', { user: USER_ID, last_studied_at: { $gte: FROM, $lt: TO } }],
    ['select', 'last_studied_at'],
  ]);
});

test('chuỗi theo ngày của admin chia ngày theo giờ Việt Nam', async () => {
  const users = fakeModel();

  await repositoryWith({ User: users }).dailyRegistrations({ since: FROM });

  assert.deepEqual(users.calls[0][1], [
    { $match: { createdAt: { $gte: FROM } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt', timezone: 'Asia/Ho_Chi_Minh' } },
        value: { $sum: 1 },
      },
    },
  ]);
});

test('thời gian thi của admin cộng duration theo taken_at', async () => {
  const history = fakeModel({ rows: [{ _id: null, seconds: 5400 }] });

  assert.equal(await repositoryWith({ LearningHistory: history }).sumExamSecondsSince({ since: FROM }), 5400);
  assert.deepEqual(history.calls[0][1], [
    { $match: { taken_at: { $gte: FROM } } },
    { $group: { _id: null, seconds: { $sum: '$duration' } } },
  ]);
});

/**
 * Lỗi gốc của module này là query vào trường không có trong model. Mọi trường
 * repository lọc hoặc gộp phải có thật trong schema.
 */
test('mọi trường repository dùng đều có trong model', () => {
  const used = [
    [ExerciseResult, ['user_id', 'exercise_id', 'completed_at', 'time_spent', 'score', 'is_passed']],
    [Exercise, ['type']],
    [LessonProgress, ['user', 'lesson', 'last_studied_at', 'is_completed', 'completed_at']],
    [Lesson, ['level']],
    [LearningHistory, ['taken_at', 'duration']],
    [User, ['createdAt', 'LanDangNhapCuoi', 'TrinhDo']],
  ];

  for (const [model, fields] of used) {
    for (const field of fields) {
      assert.ok(model.schema.path(field), `${model.modelName}.${field} không có trong model`);
    }
  }
});
