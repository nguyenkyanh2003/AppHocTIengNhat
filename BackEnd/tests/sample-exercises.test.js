import assert from 'node:assert/strict';
import test from 'node:test';

import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import { loadVideoKeyPhrases } from '../scripts/lesson-video-phrases.js';
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

const exercisesOf = (lesson) => SAMPLE_EXERCISES.filter((row) => row.lessonTitle === lesson.title).map((row) => row.exercise);
const correct = (question) => question.answers.find((a) => a.is_correct).content;

test('the correct answer is the one in the lesson word list', () => {
  const lesson = SITUATIONAL_LESSONS[0];
  const [meaning, reading] = exercisesOf(lesson);
  const first = lesson.vocabularies[0];

  assert.equal(correct(meaning.questions[0]), first.meaning);
  assert.equal(correct(reading.questions[0]), first.hiragana);
  assert.equal(meaning.level, lesson.level);
});

test('lessons without video quiz their authored dialogue', () => {
  const lesson = SITUATIONAL_LESSONS.find((l) => l.dialogue?.length > 0);
  const dialogue = exercisesOf(lesson).find((exercise) => exercise.title.startsWith('Hội thoại'));

  assert.equal(correct(dialogue.questions[0]), lesson.dialogue[0].text_vi);
  assert.equal(dialogue.type, 'Tổng hợp');
});

test('lessons with video quiz the key phrases of their video script, same exercise title as before', () => {
  const phrases = loadVideoKeyPhrases();
  const lesson = SITUATIONAL_LESSONS.find((l) => phrases.has(l.title));
  const dialogue = exercisesOf(lesson).find((exercise) => exercise.title.startsWith('Hội thoại'));
  const lessonPhrases = phrases.get(lesson.title);

  assert.equal(dialogue.title, `Hội thoại — ${lesson.title.replace(/^Tình huống:\s*/, '')}`);
  assert.equal(dialogue.questions.length, lessonPhrases.length);
  assert.equal(correct(dialogue.questions[0]), lessonPhrases[0].text_vi);
  assert.match(dialogue.description, /mẫu câu trong video/);
});

test('every lesson with video has enough distinct key phrases for a four-choice quiz', () => {
  for (const [title, list] of loadVideoKeyPhrases()) {
    assert.ok(new Set(list.map((p) => p.text_vi)).size >= 4, title);
    assert.equal(new Set(list.map((p) => p.text_ja)).size, list.length, `${title}: mẫu câu lặp lại`);
  }
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
