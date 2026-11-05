import assert from 'node:assert/strict';
import test from 'node:test';

import { createGoalRepository } from '../src/modules/goals/goal.repository.js';

/** Model giả: ghi lại lời gọi; truy vấn kết thúc bằng `lean()`. */
const fakeModel = (calls, results = {}) => {
  const chain = (name, args) => {
    calls.push([name, ...args]);
    const query = {
      sort: (order) => { calls.push(['sort', order]); return query; },
      session: (session) => { calls.push(['session', session]); return query; },
      lean: async () => results[name] ?? null,
    };
    return query;
  };
  return {
    find: (...args) => chain('find', args),
    findOne: (...args) => chain('findOne', args),
    findOneAndUpdate: (...args) => chain('findOneAndUpdate', args),
    updateOne: async (...args) => { calls.push(['updateOne', ...args]); return { modifiedCount: results.updateOne ?? 1 }; },
    deleteOne: async (filter) => { calls.push(['deleteOne', filter]); return { deletedCount: results.deleteOne ?? 1 }; },
    create: async (doc) => { calls.push(['create', doc]); return { toObject: () => ({ _id: 'g1', ...doc }) }; },
    countDocuments: async (filter) => { calls.push(['countDocuments', filter]); return results.countDocuments; },
    distinct: async (field, filter) => { calls.push(['distinct', field, filter]); return results.distinct?.[field] ?? []; },
  };
};

const AT = new Date('2026-11-04T08:00:00.000Z');

test('mọi thao tác trên một mục tiêu đều lọc theo người sở hữu', async () => {
  const calls = [];
  const repository = createGoalRepository({ LearningGoal: fakeModel(calls, { deleteOne: 0 }) });

  await repository.findByUser('u1');
  await repository.findOwned({ id: 'g1', userId: 'u1' });
  await repository.updateOwned({ id: 'g1', userId: 'u1', set: { title: 'Mới' } });
  assert.equal(await repository.deleteOwned({ id: 'g1', userId: 'u1' }), 0);

  assert.deepEqual(calls, [
    ['find', { user: 'u1' }],
    ['sort', { createdAt: -1, _id: -1 }],
    ['findOne', { _id: 'g1', user: 'u1' }],
    ['findOneAndUpdate', { _id: 'g1', user: 'u1' }, { $set: { title: 'Mới' } }, { new: true, runValidators: true }],
    ['deleteOne', { _id: 'g1', user: 'u1' }],
  ]);
});

test('ghi hoàn thành chỉ khi chưa hoàn thành và số cần đạt chưa bị sửa, trong session của hoạt động học', async () => {
  const calls = [];
  const repository = createGoalRepository({ LearningGoal: fakeModel(calls, { updateOne: 0 }) });

  assert.equal(await repository.markCompleted({ id: 'g1', userId: 'u1', target: 6, at: AT, session: 'tx' }), false);
  await repository.findIncomplete({ userId: 'u1', session: 'tx' });

  assert.deepEqual(calls, [
    ['updateOne', { _id: 'g1', user: 'u1', completed_at: null, target: 6 }, { $set: { completed_at: AT } }, { session: 'tx' }],
    ['find', { user: 'u1', completed_at: null }],
    ['session', 'tx'],
  ]);
});

test('sửa số cần đạt chỉ khớp mục tiêu chưa hoàn thành', async () => {
  const calls = [];
  const repository = createGoalRepository({ LearningGoal: fakeModel(calls) });

  await repository.updateOwned({ id: 'g1', userId: 'u1', set: { target: 10 }, onlyIfIncomplete: true });

  assert.deepEqual(calls[0], [
    'findOneAndUpdate', { _id: 'g1', user: 'u1', completed_at: null }, { $set: { target: 10 } }, { new: true, runValidators: true },
  ]);
});

test('nội dung hiện có: tổng số bài và số chữ Kanji khác nhau nằm trong bài', async () => {
  const calls = [];
  const Lesson = fakeModel(calls, { countDocuments: 40, distinct: { kanjis: ['k1', 'k2', 'k3'] } });
  const Kanji = fakeModel(calls, { distinct: { _id: ['k3', 'k4'] } });
  const repository = createGoalRepository({ LearningGoal: fakeModel(calls), Lesson, Kanji });

  assert.deepEqual(await repository.countAvailable(), { lessons: 40, kanji: 4 });
  assert.deepEqual(calls, [
    ['countDocuments', {}],
    ['distinct', 'kanjis', {}],
    ['distinct', '_id', { lessonId: { $ne: null } }],
  ]);
});
