import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildKanjiBreakdown,
  kanjiCharacters,
} from '../src/modules/vocabulary/vocabulary-kanji.js';

test('tách chữ Hán, bỏ kana và dấu lặp', () => {
  assert.deepEqual(kanjiCharacters('お名前'), ['名', '前']);
  assert.deepEqual(kanjiCharacters('時々'), ['時']);
  assert.deepEqual(kanjiCharacters('たいへんですね'), []);
});

test('ghép âm Hán-Việt của cả từ khi số âm bằng số chữ', () => {
  const breakdown = buildKanjiBreakdown({ word: '学生', hanviet: 'HỌC SINH' });

  assert.deepEqual(
    breakdown.map(({ character, hanviet, meaning }) => [character, hanviet, meaning]),
    [['学', 'HỌC', null], ['生', 'SINH', null]],
  );
});

test('lệch số âm thì không đoán, để trống', () => {
  const breakdown = buildKanjiBreakdown({ word: '今日', hanviet: 'KIM' });
  assert.deepEqual(breakdown.map((item) => item.hanviet), [null, null]);
});

test('document Kanji được ưu tiên và mang theo nghĩa', () => {
  const breakdown = buildKanjiBreakdown(
    { word: '学生', hanviet: 'HỌC SINH' },
    [{ _id: 'k1', character: '学', hanviet: 'HỌC', meaning: 'học' }],
  );

  assert.deepEqual(breakdown[0], { character: '学', hanviet: 'HỌC', meaning: 'học', kanjiId: 'k1' });
  assert.equal(breakdown[1].kanjiId, null);
});
