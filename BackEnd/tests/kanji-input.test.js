import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeKanjiInput } from '../src/modules/kanji/kanji.controller.js';

test('Kanji input accepts the canonical API contract', () => {
  assert.deepEqual(
    normalizeKanjiInput({
      lessonId: 'lesson-id',
      character: '学',
      hanviet: 'HỌC',
      onyomi: ['ガク'],
      kunyomi: 'まな.ぶ, まな.び',
      meaning: 'học',
      level: 'N5',
    }),
    {
      lessonId: 'lesson-id',
      character: '学',
      hanviet: 'HỌC',
      onyomi: ['ガク'],
      kunyomi: ['まな.ぶ', 'まな.び'],
      meaning: 'học',
      strokeOrderImage: undefined,
      level: 'N5',
      examples: undefined,
    },
  );
});

test('Kanji input keeps compatibility with the legacy Vietnamese fields', () => {
  const result = normalizeKanjiInput({
    BaiHocID: 'lesson-id',
    KyTuKanji: '日',
    AmOn: 'ニチ; ジツ',
    AmKun: 'ひ、か',
    Nghia: 'ngày',
    CapDo: 'N5',
  });

  assert.equal(result.lessonId, 'lesson-id');
  assert.equal(result.character, '日');
  assert.deepEqual(result.onyomi, ['ニチ', 'ジツ']);
  assert.deepEqual(result.kunyomi, ['ひ', 'か']);
  assert.equal(result.meaning, 'ngày');
  assert.equal(result.level, 'N5');
});
