import assert from 'node:assert/strict';
import test from 'node:test';

import Exercise from '../model/Exercise.js';
import Grammar from '../model/Grammar.js';
import JLPT from '../model/JLPT.js';
import {
  NATURAL_KEYS,
  duplicatePipeline,
  findNaturalKeyIndex,
} from '../scripts/content-indexes.js';

const MODELS = { grammars: Grammar, exercises: Exercise, jlpts: JLPT };

test('khoá tự nhiên khớp đúng khoá mà các script nhập đang dùng', () => {
  assert.deepEqual(
    NATURAL_KEYS.map(({ collection, key }) => [collection, Object.keys(key)]),
    [
      ['grammars', ['level', 'title']],
      ['exercises', ['lesson_id', 'title']],
      ['jlpts', ['title']],
    ],
  );
});

for (const spec of NATURAL_KEYS) {
  test(`${spec.label}: model khai báo unique index ${spec.name}`, () => {
    const model = MODELS[spec.collection];
    assert.equal(model.collection.collectionName, spec.collection);

    const declared = model.schema.indexes().find(([, options]) => options?.name === spec.name);
    assert.ok(declared, `model chưa khai báo index ${spec.name}`);

    const [key, options] = declared;
    assert.deepEqual(key, { ...spec.key });
    assert.equal(options.unique, true);
  });
}

test('duplicatePipeline gom theo đủ các trường khoá và chỉ giữ nhóm trùng', () => {
  assert.deepEqual(duplicatePipeline({ level: 1, title: 1 }), [
    {
      $group: {
        _id: { level: '$level', title: '$title' },
        count: { $sum: 1 },
        ids: { $push: '$_id' },
      },
    },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
  ]);
});

test('findNaturalKeyIndex chỉ nhận index unique đúng khoá', () => {
  const spec = NATURAL_KEYS[0];
  const plain = { name: 'level_1_title_1', key: { level: 1, title: 1 } };
  const unique = { name: spec.name, key: { level: 1, title: 1 }, unique: true };
  const otherKey = { name: 'title_1', key: { title: 1 }, unique: true };

  assert.equal(findNaturalKeyIndex([plain, otherKey], spec), null);
  assert.equal(findNaturalKeyIndex([plain, unique, otherKey], spec), unique);
});
