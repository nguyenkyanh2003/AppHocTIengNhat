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
const fakeModel = ({ rows = [] } = {}) => {
  const calls = [];
  const withSession = (result) => ({
    session: async (arg) => (calls.push(['session', arg]), result),
  });
  return {
    calls,
    countDocuments: (filter) => (calls.push(['countDocuments', filter]), withSession(3)),
    aggregate: (pipeline) => (calls.push(['aggregate', pipeline]), withSession(rows)),
  };
};

test('từ vựng đã học là số thẻ SRS loại Vocabulary của user', async () => {
  const srs = fakeModel();

  const count = await createAchievementRepository({ SRSProgress: srs }).countLearnedVocabulary({ userId: USER_ID });

  assert.equal(count, 3);
  assert.deepEqual(srs.calls[0], ['countDocuments', { user: USER_ID, item_type: 'Vocabulary' }]);
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
