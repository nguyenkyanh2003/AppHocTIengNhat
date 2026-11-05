import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import SRSProgress from '../model/SRSProgress.js';
import { createAchievementRepository } from '../src/modules/achievements/achievement.repository.js';

const USER_ID = '64b7f0c2a1b2c3d4e5f60700';

/**
 * Các phép đếm "đã học" ở đây là định nghĩa chung của huy hiệu **và** dashboard
 * thống kê. Bản dashboard cũ tự đếm với `item_type: 'vocabulary'` và trường
 * `status` không tồn tại nên luôn ra 0 — test giữ đúng tên trường của model.
 */
const fakeModel = ({ rows = [], distinct = [] } = {}) => {
  const calls = [];
  const withSession = (result) => ({
    session: async (arg) => (calls.push(['session', arg]), result),
  });
  return {
    calls,
    countDocuments: (filter) => (calls.push(['countDocuments', filter]), withSession(3)),
    aggregate: (pipeline) => (calls.push(['aggregate', pipeline]), withSession(rows)),
    distinct: (field, filter) => (calls.push(['distinct', field, filter]), withSession(distinct)),
  };
};

const id = (suffix) => new mongoose.Types.ObjectId(`64b7f0c2a1b2c3d4e5f607${suffix}`);

test('từ vựng đã học là hợp của thẻ SRS và "Đã nhớ" trong bài, mỗi từ tính một lần', async () => {
  const srs = fakeModel({ distinct: [id('01'), id('02')] });
  const progress = fakeModel({ distinct: [id('02'), id('03'), id('04')] });

  const count = await createAchievementRepository({ SRSProgress: srs, LessonProgress: progress })
    .countLearnedVocabulary({ userId: USER_ID, session: 'tx' });

  assert.equal(count, 4);
  assert.deepEqual(srs.calls, [
    ['distinct', 'item_id', { user: USER_ID, item_type: 'Vocabulary' }],
    ['session', 'tx'],
  ]);
  assert.deepEqual(progress.calls, [
    ['distinct', 'learned_vocabulary_ids', { user: USER_ID }],
    ['session', 'tx'],
  ]);
  assert.ok(SRSProgress.schema.path('item_type').enumValues.includes('Vocabulary'));
});

test('kanji đã học đếm ID khác nhau qua mọi bài, ép user sang ObjectId', async () => {
  const progress = fakeModel({ rows: [{ total: 5 }] });

  const count = await createAchievementRepository({ LessonProgress: progress }).countLearnedKanji({ userId: USER_ID });

  assert.equal(count, 5);
  const [, pipeline] = progress.calls[0];
  assert.ok(pipeline[0].$match.user instanceof mongoose.Types.ObjectId);
  assert.equal(String(pipeline[0].$match.user), USER_ID);
  assert.deepEqual(pipeline.slice(1), [
    { $unwind: '$learned_kanji_ids' },
    { $group: { _id: '$learned_kanji_ids' } },
    { $count: 'total' },
  ]);
});

test('chưa đánh dấu kanji nào thì đếm ra 0', async () => {
  const progress = fakeModel({ rows: [] });

  assert.equal(await createAchievementRepository({ LessonProgress: progress }).countLearnedKanji({ userId: USER_ID }), 0);
});
