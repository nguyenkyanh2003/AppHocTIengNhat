import assert from 'node:assert/strict';
import test from 'node:test';

import { scoreExerciseAnswers } from '../src/modules/exercise/exercise-scoring.service.js';

const questions = [
  {
    _id: 'question-1',
    answers: [
      { _id: 'answer-1a', is_correct: false },
      { _id: 'answer-1b', is_correct: true },
    ],
  },
  {
    _id: 'question-2',
    answers: [
      { _id: 'answer-2a', is_correct: true },
      { _id: 'answer-2b', is_correct: false },
    ],
  },
];

test('uses only the first submitted answer for each question', () => {
  const result = scoreExerciseAnswers({
    questions,
    answers: [
      { question_id: 'question-1', answer_id: 'answer-1a' },
      { question_id: 'question-1', answer_id: 'answer-1b' },
      { question_id: 'question-2', answer_id: 'answer-2a' },
    ],
  });

  assert.equal(result.correctCount, 1);
  assert.equal(result.score, 50);
  assert.equal(result.isPassed, false);
  assert.equal(result.userAnswers.length, 2);
});

test('keeps unanswered questions in the score denominator', () => {
  const result = scoreExerciseAnswers({
    questions,
    answers: [{ question_id: 'question-1', answer_id: 'answer-1b' }],
    passScore: 50,
  });

  assert.equal(result.correctCount, 1);
  assert.equal(result.totalQuestions, 2);
  assert.equal(result.score, 50);
  assert.equal(result.isPassed, true);
  assert.equal(result.userAnswers[0].correct_answer_id, 'answer-1b');
});

