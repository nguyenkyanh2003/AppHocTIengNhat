import assert from 'node:assert/strict';
import test from 'node:test';

import {
  DEMO_DUE_COUNT,
  DEMO_SRS_PROGRESS,
  DEMO_USERS,
  DEMO_VOCABULARIES,
} from '../scripts/demo-dataset.js';
import { SITUATIONAL_LESSONS } from '../scripts/situational-lessons.js';

/**
 * Bộ dữ liệu demo được nạp bằng tay vào database thật, nên sai sót chỉ lộ ra
 * lúc chạy script. Các test dưới đây kiểm những ràng buộc mà `seed-demo.js`
 * không tự bắt được và model chỉ báo khi đã kết nối DB.
 */

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

test('có đúng hai tài khoản, một học viên và một quản trị', () => {
  assert.equal(DEMO_USERS.length, 2);
  assert.deepEqual(
    DEMO_USERS.map((user) => user.role).sort(),
    ['admin', 'user'],
  );
});

test('tài khoản demo có đủ trường bắt buộc của model User', () => {
  for (const user of DEMO_USERS) {
    for (const field of ['username', 'password', 'fullName', 'email']) {
      assert.ok(user[field], `${user.username} thiếu ${field}`);
    }
    assert.ok(LEVELS.includes(user.level));
  }
});

test('username và email không trùng nhau', () => {
  const usernames = new Set(DEMO_USERS.map((user) => user.username));
  const emails = new Set(DEMO_USERS.map((user) => user.email));
  assert.equal(usernames.size, DEMO_USERS.length);
  assert.equal(emails.size, DEMO_USERS.length);
});

test('số từ vựng nằm trong khoảng 10–15 theo yêu cầu bộ demo', () => {
  assert.ok(
    DEMO_VOCABULARIES.length >= 10 && DEMO_VOCABULARIES.length <= 15,
    `đang có ${DEMO_VOCABULARIES.length} từ`,
  );
});

test('từ vựng có đủ trường bắt buộc và cấp độ hợp lệ', () => {
  for (const vocabulary of DEMO_VOCABULARIES) {
    for (const field of ['word', 'hiragana', 'meaning']) {
      assert.ok(vocabulary[field], `${vocabulary.word} thiếu ${field}`);
    }
    assert.ok(LEVELS.includes(vocabulary.level));
  }
});

test('cặp (từ, cách đọc) là duy nhất — đây là khoá upsert và unique index', () => {
  const keys = DEMO_VOCABULARIES.map((v) => `${v.word}|${v.hiragana}`);
  assert.equal(new Set(keys).size, keys.length);
});

test('mọi từ demo đều nằm trong một bài của bộ chủ đề', () => {
  const lessonWords = new Set(
    SITUATIONAL_LESSONS.flatMap((lesson) =>
      lesson.vocabularies.map((v) => `${v.word}|${v.hiragana}`),
    ),
  );

  for (const vocabulary of DEMO_VOCABULARIES) {
    assert.ok(
      lessonWords.has(`${vocabulary.word}|${vocabulary.hiragana}`),
      `${vocabulary.word} không thuộc bài nào — thẻ SRS demo sẽ không mở được bài chứa từ`,
    );
  }
});

test('bộ demo không mang theo bài học hay bài tập riêng', async () => {
  const dataset = await import('../scripts/demo-dataset.js');
  assert.equal(dataset.DEMO_LESSONS, undefined);
  assert.equal(dataset.DEMO_EXERCISES, undefined);
});

test('tiến độ SRS chỉ trỏ tới từ có trong bộ demo', () => {
  const words = new Set(DEMO_VOCABULARIES.map((vocabulary) => vocabulary.word));
  for (const row of DEMO_SRS_PROGRESS) {
    assert.ok(words.has(row.word), `${row.word} không có trong bộ từ vựng`);
  }
});

test('box của tiến độ nằm trong 1..5 theo model SRSProgress', () => {
  for (const row of DEMO_SRS_PROGRESS) {
    assert.ok(row.box >= 1 && row.box <= 5, `${row.word} có box ${row.box}`);
    assert.ok(row.streak >= 0);
  }
});

test('có cả thẻ đến hạn lẫn thẻ chưa tới hạn', () => {
  const due = DEMO_SRS_PROGRESS.filter((row) => row.dueInDays <= 0);
  const notDue = DEMO_SRS_PROGRESS.filter((row) => row.dueInDays > 0);

  assert.ok(due.length > 0, 'cần thẻ đến hạn để kiểm thử danh sách ôn');
  assert.ok(notDue.length > 0, 'cần thẻ chưa tới hạn để kiểm thử bộ lọc');
});

test('DEMO_DUE_COUNT khớp với số thẻ đến hạn thật', () => {
  const due = DEMO_SRS_PROGRESS.filter((row) => row.dueInDays <= 0).length;
  assert.equal(DEMO_DUE_COUNT, due);
});
