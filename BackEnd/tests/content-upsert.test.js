import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import { applyPlan, changedFields, parseFlags, planUpserts } from '../scripts/content-upsert.js';

const keyOf = (row) => row.character;

test('a first import creates every row', () => {
  const plan = planUpserts({ rows: [{ character: '学' }, { character: '日' }], existing: [], keyOf });

  assert.equal(plan.create.length, 2);
  assert.deepEqual(plan.update, []);
});

test('re-running the same content changes nothing, ignoring ids the database added', () => {
  const row = { character: '学', examples: [{ word: '学生', meaning: 'Học sinh' }] };
  const existing = [
    {
      _id: new mongoose.Types.ObjectId(),
      character: '学',
      // Mongoose thêm `_id` cho subdocument và giá trị mặc định cho trường file không có.
      examples: [{ _id: new mongoose.Types.ObjectId(), word: '学生', meaning: 'Học sinh' }],
      onyomi: [],
      createdAt: new Date(),
    },
  ];

  const plan = planUpserts({ rows: [row], existing, keyOf });

  assert.deepEqual(plan.unchanged, ['学']);
  assert.deepEqual(plan.create, []);
  assert.deepEqual(plan.update, []);
});

test('different content is reported with the fields that differ, keeping the existing id', () => {
  const id = new mongoose.Types.ObjectId();
  const plan = planUpserts({
    rows: [{ character: '学', meaning: 'Học tập', level: 'N5' }],
    existing: [{ _id: id, character: '学', meaning: 'Học', level: 'N5' }],
    keyOf,
  });

  assert.equal(plan.update.length, 1);
  assert.equal(plan.update[0].id, id);
  assert.deepEqual(plan.update[0].fields, ['meaning']);
});

test('a key repeated inside the file is flagged, not imported twice', () => {
  const plan = planUpserts({ rows: [{ character: '学' }, { character: '学' }], existing: [], keyOf });

  assert.equal(plan.create.length, 1);
  assert.deepEqual(plan.duplicates, ['学']);
});

test('changed fields compare dates and object ids by value', () => {
  const id = new mongoose.Types.ObjectId();
  assert.deepEqual(
    changedFields(
      { lesson_id: id, published: new Date('2026-01-01T00:00:00Z') },
      { lesson_id: new mongoose.Types.ObjectId(id.toHexString()), published: new Date('2026-01-01T00:00:00Z') },
    ),
    [],
  );
});

test('apply only overwrites existing documents when asked to, and never deletes', async () => {
  const calls = [];
  const model = {
    insertMany: async (rows) => calls.push(['insertMany', rows.length]),
    updateOne: async (filter, update) => calls.push(['updateOne', filter, update]),
    deleteMany: async () => assert.fail('không bao giờ xoá'),
  };
  const plan = {
    create: [{ character: '日' }],
    update: [{ id: 'k1', row: { character: '学', meaning: 'Học tập' } }],
    unchanged: [],
    duplicates: [],
  };

  await applyPlan({ model, plan, overwrite: false });
  assert.deepEqual(calls, [['insertMany', 1]]);

  calls.length = 0;
  await applyPlan({ model, plan, overwrite: true });
  assert.deepEqual(calls[1], ['updateOne', { _id: 'k1' }, { $set: { character: '学', meaning: 'Học tập' } }]);
});

test('unknown flags are rejected instead of silently ignored', () => {
  assert.deepEqual(parseFlags(['--dry-run']), { dryRun: true, overwrite: false });
  assert.throws(() => parseFlags(['--wipe']), /--wipe/);
});
