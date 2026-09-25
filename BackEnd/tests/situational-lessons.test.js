import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import { SITUATIONAL_LESSONS } from '../scripts/situational-lessons.js';
import { SITUATIONS } from '../src/modules/lessons/situation-catalog.js';

/**
 * Bộ bài học theo chủ đề được nạp thẳng vào database thật, và `--replace` xoá
 * mọi bài không có trong bộ này. Sai sót ở đây vì vậy không chỉ là nội dung
 * xấu — một tiêu đề trùng hay một chủ đề sai tên có thể làm mất bài.
 */

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];
const KANJI = /[一-鿿]/;

test('đúng 27 bài, chia N5 15 · N4 6 · N3 4 · N2 2', () => {
  assert.equal(SITUATIONAL_LESSONS.length, 27);

  const byLevel = Object.fromEntries(
    LEVELS.map((level) => [
      level,
      SITUATIONAL_LESSONS.filter((lesson) => lesson.level === level).length,
    ]),
  );
  assert.deepEqual(byLevel, { N5: 15, N4: 6, N3: 4, N2: 2, N1: 0 });
});

test('tiêu đề là duy nhất — đây là khoá upsert và khoá giữ lại khi --replace', () => {
  const titles = SITUATIONAL_LESSONS.map((lesson) => lesson.title);
  assert.equal(new Set(titles).size, titles.length);
});

test('thứ tự trong mỗi cấp độ chạy liên tục từ 1, không trùng', () => {
  for (const level of LEVELS) {
    const orders = SITUATIONAL_LESSONS.filter((lesson) => lesson.level === level)
      .map((lesson) => lesson.order)
      .sort((a, b) => a - b);
    assert.deepEqual(orders, orders.map((_, index) => index + 1), level);
  }
});

test('mọi bài dùng chủ đề có trong catalog', () => {
  for (const lesson of SITUATIONAL_LESSONS) {
    assert.ok(SITUATIONS.includes(lesson.situation), `${lesson.title}: ${lesson.situation}`);
  }
});

test('mỗi bài có 6–8 lượt thoại, lượt nào cũng đủ người nói, chữ Nhật, cách đọc, nghĩa', () => {
  for (const lesson of SITUATIONAL_LESSONS) {
    const count = lesson.dialogue.length;
    assert.ok(count >= 6 && count <= 8, `${lesson.title} có ${count} lượt thoại`);

    for (const turn of lesson.dialogue) {
      for (const field of ['speaker', 'text_ja', 'reading', 'text_vi']) {
        assert.ok(turn[field]?.trim(), `${lesson.title}: lượt thoại thiếu ${field}`);
      }
    }
  }
});

test('cách đọc của câu thoại và từ vựng không lẫn chữ Hán', () => {
  for (const lesson of SITUATIONAL_LESSONS) {
    for (const turn of lesson.dialogue) {
      assert.ok(!KANJI.test(turn.reading), `${lesson.title}: "${turn.reading}"`);
    }
    for (const vocabulary of lesson.vocabularies) {
      assert.ok(!KANJI.test(vocabulary.hiragana), `${lesson.title}: ${vocabulary.word}`);
    }
  }
});

test('mỗi bài có đúng 3 mục tiêu "làm được gì"', () => {
  for (const lesson of SITUATIONAL_LESSONS) {
    assert.equal(lesson.can_do_goals.length, 3, lesson.title);
  }
});

test('mỗi bài có ít nhất 8 từ vựng đủ trường, không trùng trong cùng bài', () => {
  for (const lesson of SITUATIONAL_LESSONS) {
    assert.ok(lesson.vocabularies.length >= 8, `${lesson.title} có ${lesson.vocabularies.length} từ`);

    for (const vocabulary of lesson.vocabularies) {
      for (const field of ['word', 'hiragana', 'meaning']) {
        assert.ok(vocabulary[field], `${lesson.title}: từ thiếu ${field}`);
      }
    }

    // Khoá duy nhất của Vocabulary là (word, hiragana).
    const keys = lesson.vocabularies.map((v) => `${v.word}|${v.hiragana}`);
    assert.equal(new Set(keys).size, keys.length, lesson.title);
  }
});

test('N5 bài 1–12 theo đúng thứ tự 12 chủ đề video, mỗi bài có file video riêng', () => {
  const dataDir = new URL('../data/lesson-videos/', import.meta.url);
  const videoLessons = new Map(
    fs.readdirSync(dataDir)
      .filter((name) => name.endsWith('.json'))
      .map((name) => [JSON.parse(fs.readFileSync(new URL(name, dataDir), 'utf8')).lesson.title, name]),
  );

  const n5 = SITUATIONAL_LESSONS.filter((lesson) => lesson.level === 'N5').sort((a, b) => a.order - b.order);
  for (const lesson of n5.slice(0, 12)) {
    const file = videoLessons.get(lesson.title);
    assert.ok(file, `${lesson.title} chưa có file video`);
    assert.ok(file.startsWith(`n5-${String(lesson.order).padStart(2, '0')}-`), `${file} lệch thứ tự bài ${lesson.order}`);
  }
});
