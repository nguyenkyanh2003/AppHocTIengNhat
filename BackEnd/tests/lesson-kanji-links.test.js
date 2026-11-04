import assert from 'node:assert/strict';
import test from 'node:test';

import { planLessonKanjiLinks } from '../scripts/lesson-kanji-links.js';

const lesson = (id, level, order, words, { kanjis = [] } = {}) => ({
  _id: id,
  title: `Bài ${id}`,
  level,
  order,
  kanjis,
  words,
});
const kanji = (id, character, lessonId = null) => ({ _id: id, character, lessonId });

const added = (plan) => Object.fromEntries(plan.updates.map((update) => [update.lessonId, update.added]));

test('mỗi chữ về bài đầu tiên của chương trình có nó trong từ vựng: N5 trước N4, order tăng dần', () => {
  const plan = planLessonKanjiLinks({
    lessons: [
      lesson('n4-1', 'N4', 1, ['電車']),
      lesson('n5-2', 'N5', 2, ['電車', '駅']),
      lesson('n5-1', 'N5', 1, ['学生']),
    ],
    kanjis: [kanji('k-den', '電'), kanji('k-eki', '駅'), kanji('k-gaku', '学'), kanji('k-sha', '車')],
  });

  assert.deepEqual(added(plan), { 'n5-1': ['学'], 'n5-2': ['電', '車', '駅'] });
});

test('trong một bài, chữ xếp theo thứ tự xuất hiện trong danh sách từ', () => {
  const plan = planLessonKanjiLinks({
    lessons: [lesson('l1', 'N5', 1, ['日本人', '学生'])],
    kanjis: [kanji('k-gaku', '学'), kanji('k-hito', '人'), kanji('k-nichi', '日')],
  });

  assert.deepEqual(plan.updates[0].added, ['日', '人', '学']);
  assert.deepEqual(plan.updates[0].kanjiIds, ['k-nichi', 'k-hito', 'k-gaku']);
});

test('chữ đã thuộc một bài thì không gắn lại; chữ mới nối sau các chữ bài đang có', () => {
  const plan = planLessonKanjiLinks({
    lessons: [
      lesson('l1', 'N5', 1, ['学生'], { kanjis: ['k-gaku'] }),
      lesson('l2', 'N5', 2, ['大学', '大きい']),
    ],
    kanjis: [kanji('k-gaku', '学'), kanji('k-dai', '大'), kanji('k-sei', '生')],
  });

  assert.deepEqual(added(plan), { l1: ['生'], l2: ['大'] });
  assert.deepEqual(plan.updates.find((update) => update.lessonId === 'l1').kanjiIds, ['k-gaku', 'k-sei']);
});

test('bài chưa có mảng kanjis thì giữ các chữ đang trỏ về bài qua lessonId', () => {
  const plan = planLessonKanjiLinks({
    lessons: [lesson('l1', 'N5', 1, ['日本'])],
    kanjis: [kanji('k-hon', '本', 'l1'), kanji('k-nichi', '日')],
  });

  assert.deepEqual(plan.updates, [{ lessonId: 'l1', title: 'Bài l1', kanjiIds: ['k-hon', 'k-nichi'], added: ['日'] }]);
});

test('chữ không có trong từ vựng của bài nào được báo riêng, không gắn bừa', () => {
  const plan = planLessonKanjiLinks({
    lessons: [lesson('l1', 'N5', 1, ['水'])],
    kanjis: [kanji('k-mizu', '水'), kanji('k-yama', '山')],
  });

  assert.deepEqual(plan.unmatched, ['山']);
});

test('chạy lại sau khi đã ghi thì không còn gì để làm', () => {
  const lessons = [lesson('l1', 'N5', 1, ['電車']), lesson('l2', 'N5', 2, ['駅'])];
  const kanjis = [kanji('k-den', '電'), kanji('k-eki', '駅')];

  const first = planLessonKanjiLinks({ lessons, kanjis });
  const written = lessons.map((row) => ({
    ...row,
    kanjis: first.updates.find((update) => update.lessonId === row._id)?.kanjiIds ?? row.kanjis,
  }));

  assert.deepEqual(planLessonKanjiLinks({ lessons: written, kanjis }).updates, []);
});
