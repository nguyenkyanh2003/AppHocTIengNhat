import assert from 'node:assert/strict';
import test from 'node:test';

import {
  DEMO_DUE_COUNT,
  DEMO_EXERCISES,
  DEMO_LESSONS,
  DEMO_SRS_PROGRESS,
  DEMO_USERS,
  DEMO_VOCABULARIES,
} from '../scripts/demo-dataset.js';

/**
 * Bộ dữ liệu demo được nạp bằng tay vào database thật, nên sai sót chỉ lộ ra
 * lúc chạy script. Các test dưới đây kiểm những ràng buộc mà `seed-demo.js`
 * không tự bắt được và model chỉ báo khi đã kết nối DB.
 */

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];
const EXERCISE_TYPES = ['Từ vựng', 'Ngữ pháp', 'Kanji', 'Tổng hợp'];

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

test('tiêu đề bài học là duy nhất — đây là khoá upsert', () => {
  const titles = new Set(DEMO_LESSONS.map((lesson) => lesson.title));
  assert.equal(titles.size, DEMO_LESSONS.length);
});

test('số từ vựng nằm trong khoảng 10–15 theo yêu cầu bộ demo', () => {
  assert.ok(
    DEMO_VOCABULARIES.length >= 10 && DEMO_VOCABULARIES.length <= 15,
    `đang có ${DEMO_VOCABULARIES.length} từ`,
  );
});

test('mọi từ vựng trỏ tới một bài học có thật', () => {
  const titles = new Set(DEMO_LESSONS.map((lesson) => lesson.title));
  for (const vocabulary of DEMO_VOCABULARIES) {
    assert.ok(
      titles.has(vocabulary.lessonTitle),
      `${vocabulary.word} trỏ tới bài học không tồn tại`,
    );
  }
});

test('từ vựng có đủ trường bắt buộc và cấp độ hợp lệ', () => {
  for (const vocabulary of DEMO_VOCABULARIES) {
    for (const field of ['word', 'hiragana', 'meaning']) {
      assert.ok(vocabulary[field], `${vocabulary.word} thiếu ${field}`);
    }
    assert.ok(LEVELS.includes(vocabulary.level));
  }
});

test('cặp (từ, bài học) là duy nhất — đây là khoá upsert', () => {
  const keys = DEMO_VOCABULARIES.map((v) => `${v.word}@${v.lessonTitle}`);
  assert.equal(new Set(keys).size, keys.length);
});

test('mỗi bài học đều có ít nhất một từ vựng', () => {
  for (const lesson of DEMO_LESSONS) {
    const count = DEMO_VOCABULARIES.filter(
      (vocabulary) => vocabulary.lessonTitle === lesson.title,
    ).length;
    assert.ok(count > 0, `${lesson.title} chưa có từ nào`);
  }
});

test('bài tập trỏ tới bài học có thật và dùng type hợp lệ', () => {
  const titles = new Set(DEMO_LESSONS.map((lesson) => lesson.title));
  for (const exercise of DEMO_EXERCISES) {
    assert.ok(titles.has(exercise.lessonTitle), exercise.title);
    assert.ok(EXERCISE_TYPES.includes(exercise.type), exercise.type);
    assert.ok(LEVELS.includes(exercise.level));
  }
});

test('mỗi câu hỏi có 2–4 đáp án theo validator của model Exercise', () => {
  for (const exercise of DEMO_EXERCISES) {
    assert.ok(exercise.questions.length > 0, exercise.title);
    for (const question of exercise.questions) {
      const count = question.answers.length;
      assert.ok(
        count >= 2 && count <= 4,
        `"${question.content}" có ${count} đáp án`,
      );
    }
  }
});

test('mỗi câu hỏi có đúng một đáp án đúng', () => {
  for (const exercise of DEMO_EXERCISES) {
    for (const question of exercise.questions) {
      const correct = question.answers.filter(
        (answer) => answer.is_correct,
      ).length;
      assert.equal(correct, 1, `"${question.content}" có ${correct} đáp án đúng`);
    }
  }
});

test('bộ demo chạm được biên dưới 2 đáp án của validator', () => {
  const counts = DEMO_EXERCISES.flatMap((exercise) =>
    exercise.questions.map((question) => question.answers.length),
  );
  assert.ok(
    counts.includes(2),
    'cần ít nhất một câu 2 đáp án để chạm biên dưới',
  );
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
