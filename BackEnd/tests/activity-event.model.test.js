import assert from 'node:assert/strict';
import test from 'node:test';
import ActivityEvent from '../model/ActivityEvent.js';

const schema = ActivityEvent.schema;
const indexOn = (fields) =>
  schema.indexes().find(([keys]) => JSON.stringify(keys) === JSON.stringify(fields));

test('the ten fields the spec names are all declared', () => {
  for (const field of [
    'user',
    'event_key',
    'type',
    'source_id',
    'occurred_at',
    'day_key',
    'xp_delta',
    'reason',
    'counts_as_study',
    'policy_version',
  ]) {
    assert.ok(schema.path(field), `thiếu trường ${field}`);
  }
});

test('identity, day and policy stamp are required; nothing can be written half-identified', () => {
  for (const field of ['user', 'event_key', 'type', 'occurred_at', 'day_key', 'policy_version']) {
    assert.equal(schema.path(field).isRequired, true, `${field} phải required`);
  }
});

test('xp_delta and counts_as_study have safe defaults', () => {
  // Một event không khai XP là event 0 XP, không phải `undefined` — lịch sử XP
  // cộng dồn trường này nên `undefined` sẽ thành NaN ở `$inc`/`$sum`.
  assert.equal(schema.path('xp_delta').defaultValue, 0);
  assert.equal(schema.path('counts_as_study').defaultValue, false);
});

test('a receipt slot exists for submit retries', () => {
  assert.ok(schema.path('receipt'), 'thiếu receipt cho retry nộp bài (spec §3.3)');
  assert.equal(schema.path('receipt').isRequired, undefined);
});

test('the duplicate guard is a unique index on (user, event_key)', () => {
  const index = indexOn({ user: 1, event_key: 1 });
  assert.ok(index, 'thiếu index (user, event_key)');
  assert.equal(index[1].unique, true, 'index chống trùng phải unique');
});

test('the history index carries _id so the cursor can break ties', () => {
  // `xp-history?mode=page` sort `occurred_at DESC, _id DESC` (§4.2). Thiếu
  // `_id` trong index thì hai event cùng mốc thời gian có thứ tự không ổn
  // định giữa hai trang, và cursor sẽ nhảy cóc hoặc lặp bản ghi.
  const index = indexOn({ user: 1, occurred_at: -1, _id: -1 });
  assert.ok(index, 'thiếu index lịch sử (user, occurred_at, _id)');
  assert.notEqual(index[1].unique, true);
});

test('no index expires event keys', () => {
  // Khoá sự kiện là thứ đang chặn việc phát thưởng lại. TTL ở đây nghĩa là
  // sau N ngày, gửi lại đúng lần nộp cũ sẽ được cộng XP lần nữa (spec §3.2).
  for (const [, options] of schema.indexes()) {
    assert.equal(options.expireAfterSeconds, undefined, 'không được đặt TTL');
  }
  assert.equal(schema.path('occurred_at').options.expires, undefined);
});

test('the legacy XpEvent model is gone', async () => {
  await assert.rejects(import('../model/XpEvent.js'), /Cannot find module|ERR_MODULE_NOT_FOUND/);
});
