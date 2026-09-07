import assert from 'node:assert/strict';
import test from 'node:test';

import {
  normalizeSubmittedAnswers,
  scoreExamAnswers,
} from '../src/modules/jlpt/jlpt-scoring.service.js';

const sections = {
  moji_goi: [{ _id: 'moji-id', correct_answer: 1, score: 2 }],
  bunpou: [{ _id: 'bunpou-id', correct_answer: 0, score: 3 }],
  dokkai: [{ questions: [{ _id: 'dokkai-id', correct_answer: 2, score: 4 }] }],
  choukai: [{ questions: [{ _id: 'choukai-id', correct_answer: 3, score: 5 }] }],
};

test('normalizes every currently supported answer field alias', () => {
  const normalized = normalizeSubmittedAnswers([
    { question_key: 'moji-0', selected: 1 },
    { questionKey: 'bunpou-0', answer: 0 },
    { key: 'dokkai-0-0', option: 2 },
    { section: 'ignored-without-key', choice: 0 },
  ]);

  assert.deepEqual(normalized.map(({ key, choice }) => ({ key, choice })), [
    { key: 'moji-0', choice: 1 },
    { key: 'bunpou-0', choice: 0 },
    { key: 'dokkai-0-0', choice: 2 },
  ]);
});

test('preserves JLPT section scoring and numeric choice coercion', () => {
  const result = scoreExamAnswers({
    sections,
    rawAnswers: [
      { key: 'moji_goi_0', choice: '1' },
      { key: 'bunpou-0', choice: 2 },
      { key: 'dokkai_0_0', choice: 2 },
      { key: 'choukai-0-0', choice: 3 },
    ],
  });

  assert.equal(result.correctCount, 3);
  assert.equal(result.totalScore, 11);
  assert.deepEqual(result.sectionScores, {
    moji_goi: 2,
    bunpou: 0,
    dokkai: 4,
    choukai: 5,
  });
  assert.equal(result.answerDetails.length, 4);
});
