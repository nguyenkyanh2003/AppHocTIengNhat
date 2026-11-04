import assert from 'node:assert/strict';
import test from 'node:test';

import SRSProgress from '../model/SRSProgress.js';
import { CARD_KEY, LEGACY_KEY, planCardIndex } from '../scripts/srs-card-index.js';
import { ITEM_TYPES } from '../src/modules/srs/srs-scheduling.js';

const index = (name, key, unique = false) => ({ name, key, ...(unique ? { unique } : {}) });

test('model khai báo unique index của thẻ theo user, loại và nội dung — không còn khoá cũ', () => {
  const declared = SRSProgress.schema.indexes();
  const card = declared.find(([, options]) => options?.name === CARD_KEY.name);

  assert.ok(card, `model chưa khai báo index ${CARD_KEY.name}`);
  assert.deepEqual(Object.entries(card[0]), Object.entries(CARD_KEY.key));
  assert.equal(card[1].unique, true);
  assert.equal(
    declared.some(([key]) => JSON.stringify(key) === JSON.stringify(LEGACY_KEY)),
    false,
  );
});

test('loại thẻ của API khớp enum item_type của model', () => {
  assert.deepEqual(SRSProgress.schema.path('item_type').enumValues, [...ITEM_TYPES]);
});

test('DB còn khoá cũ: tạo khoá mới rồi xoá khoá cũ', () => {
  const plan = planCardIndex([
    index('_id_', { _id: 1 }),
    index('user_1', { user: 1 }),
    index('user_1_item_id_1', { user: 1, item_id: 1 }, true),
  ]);

  assert.deepEqual(plan, { create: true, drop: ['user_1_item_id_1'] });
});

test('Mongoose đã tự tạo khoá mới lúc khởi động: chỉ còn việc xoá khoá cũ', () => {
  const plan = planCardIndex([
    index('user_1_item_id_1', { user: 1, item_id: 1 }, true),
    index('srs_card_key', { user: 1, item_type: 1, item_id: 1 }, true),
  ]);

  assert.deepEqual(plan, { create: false, drop: ['user_1_item_id_1'] });
});

test('đã chuyển xong thì không còn việc gì', () => {
  assert.deepEqual(planCardIndex([index('srs_card_key', { user: 1, item_type: 1, item_id: 1 }, true)]), {
    create: false,
    drop: [],
  });
});

test('index cùng trường nhưng sai thứ tự hoặc không unique không được tính là khoá mới', () => {
  assert.equal(planCardIndex([index('x', { user: 1, item_id: 1, item_type: 1 }, true)]).create, true);
  assert.equal(planCardIndex([index('y', { user: 1, item_type: 1, item_id: 1 })]).create, true);
});
