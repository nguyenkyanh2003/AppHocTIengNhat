import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import { buildChoices, SAMPLE_EXERCISES } from '../scripts/sample-exercises.js';
import { SITUATIONAL_LESSONS } from '../scripts/situational-lessons.js';

/**
 * Bài tập mẫu được nạp thẳng vào DB demo, nên lỗi dữ liệu chỉ lộ ra khi người
 * học làm bài. Kiểm ở đây những gì model không tự bắt được: đúng một đáp án
 * đúng, đáp án không trùng chữ, và đáp án đúng khớp bảng từ của bài.
 */

test('every topic lesson gets a meaning, a reading and a dialogue exercise', () => {
  assert.equal(SAMPLE_EXERCISES.length, SITUATIONAL_LESSONS.length * 3);

  const keys = SAMPLE_EXERCISES.map(({ lessonTitle, exercise }) => `${lessonTitle}:${exercise.title}`);
  assert.equal(new Set(keys).size, keys.length, 'tiêu đề bài tập không được trùng trong một bài');
});

test('every exercise passes the Exercise model validation', () => {
  const lessonId = new mongoose.Types.ObjectId();
  for (const { exercise } of SAMPLE_EXERCISES) {
    const error = new Exercise({ ...exercise, lesson_id: lessonId }).validateSync();
    assert.equal(error, undefined, `${exercise.title}: ${error?.message}`);
  }
});

test('every question has four distinct answers and exactly one is correct', () => {
  for (const { exercise } of SAMPLE_EXERCISES) {
    for (const question of exercise.questions) {
      const contents = question.answers.map((answer) => answer.content);
      assert.equal(contents.length, 4, question.content);
      assert.equal(new Set(contents).size, 4, `đáp án trùng: ${question.content}`);
      assert.equal(question.answers.filter((answer) => answer.is_correct).length, 1, question.content);
    }
  }
});

test('the correct answer is the one in the lesson word list', () => {
  const lesson = SITUATIONAL_LESSONS[0];
  const [{ exercise: meaning }, { exercise: reading }, { exercise: dialogue }] = SAMPLE_EXERCISES.filter(
    (row) => row.lessonTitle === lesson.title,
  );
  const first = lesson.vocabularies[0];

  assert.equal(meaning.questions[0].answers.find((a) => a.is_correct).content, first.meaning);
  assert.equal(reading.questions[0].answers.find((a) => a.is_correct).content, first.hiragana);
  assert.equal(dialogue.questions[0].answers.find((a) => a.is_correct).content, lesson.dialogue[0].text_vi);
  assert.equal(dialogue.type, 'Tổng hợp');
  assert.equal(meaning.level, lesson.level);
});

test('kana-only words are not asked for their reading', () => {
  for (const { exercise } of SAMPLE_EXERCISES.filter((row) => row.exercise.title.startsWith('Cách đọc'))) {
    for (const question of exercise.questions) {
      const word = /「(.+)」/.exec(question.content)[1];
      const correct = question.answers.find((a) => a.is_correct).content;
      assert.notEqual(word, correct);
    }
  }
});

test('choices are deterministic and rotate the correct position', () => {
  const pool = ['a', 'b', 'c', 'd', 'e'].map((meaning) => ({ meaning }));
  const pick = (word) => word.meaning;

  assert.deepEqual(buildChoices(pool, 1, pick), buildChoices(pool, 1, pick));
  assert.equal(buildChoices(pool, 0, pick).findIndex((a) => a.is_correct), 0);
  assert.equal(buildChoices(pool, 2, pick).findIndex((a) => a.is_correct), 2);
  // Không đủ ba đáp án nhiễu khác chữ thì không dựng câu hỏi.
  assert.equal(buildChoices([{ meaning: 'a' }, { meaning: 'a' }, { meaning: 'b' }], 0, pick), null);
});
