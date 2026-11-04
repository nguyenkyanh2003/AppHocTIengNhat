import assert from 'node:assert/strict';
import test from 'node:test';

import { createKanjiRepository } from '../src/modules/kanji/kanji.repository.js';

test('findLessonsUsing tìm bài có chữ trong mảng kanjis, chỉ lấy tên bài', async () => {
  const calls = [];
  const Lesson = {
    find(filter) {
      calls.push(['find', filter]);
      const chain = {
        select(fields) { calls.push(['select', fields]); return chain; },
        lean: async () => [{ _id: 'l1', title: 'Tình huống: Đi tàu' }],
      };
      return chain;
    },
  };
  const repository = createKanjiRepository({ Kanji: {}, Lesson });

  const lessons = await repository.findLessonsUsing('k1');

  assert.deepEqual(calls, [['find', { kanjis: 'k1' }], ['select', 'title']]);
  assert.deepEqual(lessons, [{ _id: 'l1', title: 'Tình huống: Đi tàu' }]);
});
