import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import { createSrsRepository } from '../src/modules/srs/srs.repository.js';

const USER_ID = '64b7f0c2a1b2c3d4e5f60700';

/**
 * Model giả ghi lại lệnh **cùng đối số** — lỗi của tầng này là sai tên trường,
 * sai toán tử hay quên `session`, mà test chỉ kiểm "có được gọi" không bắt được.
 */
const fakeModel = ({ result = null, createError = null, afterCreateError = null } = {}) => {
  const calls = [];
  const chain = (rows) => {
    const self = {
      sort: (arg) => (calls.push(['sort', arg]), self),
      limit: (arg) => (calls.push(['limit', arg]), self),
      select: (arg) => (calls.push(['select', arg]), self),
      session: (arg) => (calls.push(['session', arg]), self),
      lean: async () => rows,
    };
    return self;
  };
  let created = false;
  return {
    calls,
    find: (filter) => (calls.push(['find', filter]), chain(Array.isArray(result) ? result : [])),
    findOne: (filter) => (calls.push(['findOne', filter]), chain(created ? afterCreateError : result)),
    create: async (doc) => {
      calls.push(['create', doc]);
      created = true;
      if (createError) throw createError;
      return { toObject: () => ({ _id: 'p1', ...doc }) };
    },
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return result;
    },
    countDocuments: async (filter) => (calls.push(['countDocuments', filter]), 3),
    aggregate: async (pipeline) => (calls.push(['aggregate', pipeline]), []),
    deleteOne: async (filter) => (calls.push(['deleteOne', filter]), { deletedCount: 1 }),
    exists: (filter) => (calls.push(['exists', filter]), chain({ _id: 'v1' })),
  };
};

const repositoryWith = (model, content = fakeModel()) =>
  createSrsRepository({ SRSProgress: model, contentModels: { Vocabulary: content } });

test('due batch filters by user, type and due time, excluding items before sort and limit', async () => {
  const model = fakeModel();
  const now = new Date('2026-09-20T00:00:00Z');

  await repositoryWith(model).findDueBatch({
    userId: 'u1',
    itemType: 'Vocabulary',
    now,
    excludeItemIds: ['a', 'b'],
    limit: 20,
  });

  assert.deepEqual(model.calls, [
    [
      'find',
      { user: 'u1', item_type: 'Vocabulary', next_review: { $lte: now }, item_id: { $nin: ['a', 'b'] } },
    ],
    ['sort', { next_review: 1, _id: 1 }],
    ['limit', 20],
  ]);
});

test('compare-and-set matches the state that was read, requires due for reviews and never upserts', async () => {
  const model = fakeModel({ result: { _id: 'p1' } });
  const progress = { _id: 'p1', user: 'u1', item_id: 'v1', item_type: 'Vocabulary', box: 2, streak: 1 };
  const expected = new Date('2026-09-19T00:00:00Z');
  const now = new Date('2026-09-20T00:00:00Z');
  const next = { box: 3, streak: 2, next_review: new Date('2026-09-27T00:00:00Z') };

  await repositoryWith(model).compareAndSet({ progress, expectedNextReview: expected, dueBy: now, next, session: 's' });
  await repositoryWith(model).compareAndSet({ progress, expectedNextReview: expected, next });

  const [[, reviewFilter, update, options], [, resetFilter]] = model.calls;
  assert.deepEqual(reviewFilter, { ...progress, next_review: { $eq: expected, $lte: now } });
  assert.deepEqual(update, { $set: next });
  assert.equal(options.upsert, undefined);
  assert.equal(options.new, true);
  assert.equal(options.session, 's');
  assert.deepEqual(resetFilter, { ...progress, next_review: expected });
});

test('ensure progress creates once and reads back the winner after a duplicate key', async () => {
  const winner = { _id: 'p-winner', box: 1 };
  const duplicate = Object.assign(new Error('E11000'), { code: 11000 });
  const model = fakeModel({ createError: duplicate, afterCreateError: winner });
  const initial = { box: 1, streak: 0, next_review: new Date('2026-09-21T00:00:00Z') };

  const result = await repositoryWith(model).ensureProgress({
    userId: 'u1',
    itemId: 'v1',
    itemType: 'Vocabulary',
    initial,
  });

  assert.deepEqual(result, { progress: winner, created: false });
  const [, doc] = model.calls.find(([name]) => name === 'create');
  assert.deepEqual(doc, { user: 'u1', item_id: 'v1', item_type: 'Vocabulary', ...initial });
});

test('ensure progress keeps an existing schedule untouched', async () => {
  const existing = { _id: 'p1', box: 4 };
  const model = fakeModel({ result: existing });

  const result = await repositoryWith(model).ensureProgress({
    userId: 'u1',
    itemId: 'v1',
    itemType: 'Vocabulary',
    initial: { box: 1, streak: 0, next_review: new Date() },
  });

  assert.deepEqual(result, { progress: existing, created: false });
  assert.equal(model.calls.some(([name]) => name === 'create'), false);
});

test('box counts cast the user id, because aggregate does not', async () => {
  const model = fakeModel();

  await repositoryWith(model).countByBox({ userId: USER_ID, itemType: 'Vocabulary' });

  const [[, pipeline]] = model.calls;
  assert.ok(pipeline[0].$match.user instanceof mongoose.Types.ObjectId);
  assert.equal(String(pipeline[0].$match.user), USER_ID);
});

test('content for a batch is read in one query, and nothing is queried for an empty batch', async () => {
  const content = fakeModel({ result: [{ _id: 'v1' }] });
  const repository = repositoryWith(fakeModel(), content);

  assert.deepEqual(await repository.findContentByIds({ itemType: 'Vocabulary', ids: [] }), []);
  assert.equal(content.calls.length, 0);

  await repository.findContentByIds({ itemType: 'Vocabulary', ids: ['v1', 'v2'] });
  assert.deepEqual(content.calls[0], ['find', { _id: { $in: ['v1', 'v2'] } }]);
});

test('delete only touches the current user card', async () => {
  const model = fakeModel();

  assert.equal(await repositoryWith(model).deleteProgress({ userId: 'u1', itemId: 'v1', itemType: 'Vocabulary' }), 1);
  assert.deepEqual(model.calls[0], ['deleteOne', { user: 'u1', item_id: 'v1', item_type: 'Vocabulary' }]);
});
