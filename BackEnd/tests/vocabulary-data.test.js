import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import { SITUATIONAL_LESSONS } from '../scripts/situational-lessons.js';
import { reviewFixes } from '../src/modules/vocabulary/vocabulary-fixes.js';
import { parseCsv } from '../src/modules/vocabulary/vocabulary-import.file.js';
import { mapHeaders, reviewRows } from '../src/modules/vocabulary/vocabulary-import.review.js';
import { reviewTagRows, tagKey } from '../src/modules/vocabulary/vocabulary-tags.review.js';

/**
 * Kho từ vựng dựng lại từ repo phải ra đúng kho đang chạy: nhập các file trong
 * `data/vocabulary/`, áp `vocabulary-fixes.json` (không còn gì để ghi), seed bài
 * tình huống, gắn `vocabulary-tags.json`. Test này giữ bốn nguồn đó khớp nhau mà
 * không cần MongoDB.
 */

const LEVEL_FILES = Object.freeze({ N5: 'n5.csv', N4: 'n4.csv', N3: 'n3.csv', N2: 'n2.csv', N1: 'n1.csv' });
const LEGACY_FILE = 'legacy-lessons.csv';

const read = (path) => fs.readFileSync(new URL(path, import.meta.url), 'utf8');

const importFile = (name) => {
  const { headers, rows } = parseCsv(read(`../data/vocabulary/${name}`));
  const columns = mapHeaders(headers);
  assert.deepEqual(columns.missing, [], `${name} thiếu cột`);
  return { rows, ...reviewRows(rows, { columns }) };
};

const files = Object.fromEntries(
  [...Object.values(LEVEL_FILES), LEGACY_FILE].map((name) => [name, importFile(name)]),
);
const stored = new Map(
  Object.values(files).flatMap(({ accepted }) => accepted.map((row) => [tagKey(row), row])),
);

/** Khoá từ của bài tình huống; dòng có `link` trỏ tới từ giáo trình đã có. */
const lessonKeys = new Set(
  SITUATIONAL_LESSONS.flatMap((lesson) => lesson.vocabularies.map((row) => tagKey(row.link ?? row))),
);

test('mỗi file trong data/vocabulary nhập được trọn vẹn, đúng cấp của file', () => {
  for (const [name, { rows, accepted, errors }] of Object.entries(files)) {
    assert.deepEqual(errors, [], name);
    assert.equal(accepted.length, rows.length, name);
    assert.ok(accepted.every((row) => row.level), `${name}: dòng thiếu cấp độ`);
  }
  for (const [level, name] of Object.entries(LEVEL_FILES)) {
    const wrong = files[name].accepted.filter((row) => row.level !== level);
    assert.deepEqual(wrong.map((row) => row.word), [], `${name} chứa từ khác cấp`);
  }
});

test('một từ chỉ nằm ở một file', () => {
  const total = Object.values(files).reduce((sum, { accepted }) => sum + accepted.length, 0);
  assert.equal(stored.size, total);
});

test('nhãn chia bộ phủ đúng kho: từ trong các file cộng từ của bài tình huống', () => {
  const { accepted: tags, errors } = reviewTagRows(JSON.parse(read('../data/vocabulary-tags.json')));
  assert.deepEqual(errors, []);
  const tagged = new Map(tags.map((row) => [tagKey(row), row.level]));

  const untagged = [...stored.keys(), ...lessonKeys].filter((key) => !tagged.has(key));
  assert.deepEqual(untagged, [], 'từ không có nhãn thì không nằm trong bộ học nào');
  const stray = [...tagged.keys()].filter((key) => !stored.has(key) && !lessonKeys.has(key));
  assert.deepEqual(stray, [], 'nhãn của từ không còn trong kho');

  const wrongLevel = [...stored].filter(([key, row]) => tagged.get(key) !== row.level);
  assert.deepEqual(wrongLevel.map(([key]) => key), []);
});

test('file sửa đã nằm sẵn trong các file: kho dựng mới chạy file sửa không còn gì để ghi', () => {
  const { accepted: fixes, errors } = reviewFixes(JSON.parse(read('../data/vocabulary-fixes.json')));
  assert.deepEqual(errors, []);
  const exists = (key) => stored.has(tagKey(key)) || lessonKeys.has(tagKey(key));

  for (const fix of fixes) {
    const label = `${fix.source} · ${fix.action}`;
    const present = {
      add: [fix],
      'set-meaning': [fix],
      'set-hanviet': [fix],
      skip: [fix],
      rename: [fix.to],
      remove: [fix.keep],
      merge: [fix.into],
    }[fix.action];
    const gone = { rename: [fix.from], remove: [fix], merge: [fix] }[fix.action] ?? [];

    for (const key of present) assert.ok(exists(key), `${label}: thiếu ${key.word} (${key.hiragana})`);
    for (const key of gone) assert.ok(!exists(key), `${label}: còn ${key.word} (${key.hiragana})`);

    const row = stored.get(tagKey(fix.action === 'rename' ? fix.to : fix));
    if (!row) continue;
    if (fix.action === 'set-meaning') assert.equal(row.meaning, fix.to, label);
    if (fix.action === 'set-hanviet') assert.equal(row.hanviet ?? '', fix.to, label);
    if (fix.action === 'rename' && fix.to.meaning) assert.equal(row.meaning, fix.to.meaning, label);
    if (fix.action === 'rename' && fix.to.hanviet) assert.equal(row.hanviet, fix.to.hanviet, label);
    if (fix.action === 'add') assert.equal(row.level, fix.level, label);
  }
});
